-- Config --
local taxCfg = {}
taxCfg.defaultRate = 0.5
taxCfg.currentRate = 0.5
taxCfg.rateLimits = {}
taxCfg.rateLimits.min = 0
taxCfg.rateLimits.max = 1
taxCfg.pays = { 
	{"Mayor", 25, {"Mayor"}, {7}},
	{"Chief", 25, {"Civil Protection Chief"}, {6}},
	{"Civil Protection", 50, {"Civil Protection"}, {2}}
}
local payable = {}

local function printPayable()
	print(string.format("--Payable players-- n=%d", #payable))
	for i, ply2 in ipairs(payable) do
		print(ply2)
	end
end

function isPayable(ply)
	for i, ply2 in ipairs(payable) do
		if(ply2 == ply) then
			return true
		end
	end
	return false
end

function jobIDGetsPayed(jobId)
	for _, payTable in ipairs(taxCfg.pays) do
		for _, id in ipairs(payTable[4]) do
			if(jobId == id) then
				return true
			end
		end
	end
	return false
end

function removeFromPayable(ply)
	for i, ply2 in ipairs(payable) do
		if(ply == ply2) then table.remove(payable, i) end
	end
end

function repairPayable()
	payable = {}
	for _, ply in ipairs(player.GetAll()) do
		if(jobIDGetsPayed(ply:Team())) then
			table.insert(payable, ply)
		end
	end
end
repairPayable()

function jobChange(ply, before, after)
	afterPay = jobIDGetsPayed(after)
	removeFromPayable(ply)
	if(afterPay) then table.insert(payable, ply) end
	print(#payable)
	for i, ply2 in ipairs(payable) do
		print(i, ply2)
	end
end
hook.Add("OnPlayerChangedTeam", "taxJobChange", jobChange)

local meta = FindMetaTable("Player")

function meta:addTax(amnt)
	self.taxBal = self.taxBal + amnt
	return
end
function meta:resetTax(amnt)
	local temp = self.taxBal
	self.taxBal = 0
	return temp
end


local function taxPaymentFunc(ply, amnt)
	if not ply.taxBal then ply.taxBal = 0 end
	
	if(isPayable(ply)) then
		local taxAmnt = ply:resetTax()
		amnt = amnt + taxAmnt
		if(taxAmnt > 0) then
			return false, string.format("You have been paid $%d, $%d granted as tax collection", amnt, taxAmnt), amnt
		else
			return false, string.format("You have been paid $%d", amnt), amnt
		end
	end
		

	local taxAmnt = amnt * taxCfg.currentRate
	taxAmnt = math.floor(taxAmnt)
	amnt = amnt - taxAmnt
	
	local ptMultiplier = 0
	for _, payout in ipairs(taxCfg.pays) do
		ptMultiplier = ptMultiplier + payout[2]
	end
	ptMultiplier = 100 / ptMultiplier

	local payouts = {}
	for _, ply2 in ipairs(player.GetAll()) do
		local plyJob = ply2:getJobTable()
		local jobName = plyJob.name
		for _, payTable in ipairs(taxCfg.pays) do
			for _, jobStr in ipairs(payTable[3]) do
				if(jobName == jobStr) then
					table.insert(payouts, {ply2, payTable})
					goto outercontinue
				end
			end
		end
		::outercontinue::
	end

	
	if(#payouts > 0) then
		local ptTotal = 0
		for _, payout in ipairs(payouts) do
			ptTotal = ptTotal + payout[2][2]
		end

		local ptValue = taxAmnt/ptTotal
		for _, payout in ipairs(payouts) do
			local ply2 = payout[1]
			local payTable = payout[2]
			ply2:addTax(ptMultiplier * ptValue * payTable[2])
		end
	end
	return false, string.format("You have been paid $%d, $%d taken as taxes", amnt, taxAmnt), amnt
end
hook.Add("playerGetSalary", "taxSalary", taxPaymentFunc)



util.AddNetworkString("taxSetFailNotQualified")
util.AddNetworkString("invalidCommand")
util.AddNetworkString("setTaxSucceed")
util.AddNetworkString("setPaySucceed")

function sendError(ply)
	net.Start("invalidCommand") 
	net.Send(ply) 
	return
end

function setTaxRate(ply, cmd, args)
	if(ply:isMayor()) then
		print("mayor set rate")
	else
		net.Start("taxSetFailNotQualified")
		net.Send(ply)
	end
end
concommand.Add("taxRate", setTaxRate)

function setTaxRate(ply, cmd, args)
	if(#args < 1) then sendError(ply) return end
	if(ply:isMayor()) then
		local input = tonumber(args[1])
		if not input then sendError(ply) return end
		print(taxCfg.rateLimits.max)
		if(taxCfg.rateLimits.min <= input and input <= taxCfg.rateLimits.max) then
			taxCfg.currentRate = input
			net.Start("setTaxSucceed")
			net.WriteDouble(input)
			net.Send(ply)
		else
			sendError(ply)
		end
	else
		net.Start("taxSetFailNotQualified")
		net.Send(ply)
	end
end
concommand.Add("taxRate", setTaxRate)

function setPayRate(ply, cmd, args)
	if(#args < 2) then sendError(ply) return end

	value = tonumber(args[2])
	if not value then sendError(ply) return end

	for _, payTable in ipairs(taxCfg.pays) do
		for _, jobStr in ipairs(payTable[3]) do
			if(jobStr == args[1]) then
				payTable[2] = value
				net.Start("setPaySucceed")
				net.WriteString(payTable[1])
				net.WriteDouble(value)
				net.Send(ply)
				return
			end
		end
	end
	sendError(ply) 
	return
end
concommand.Add("payRate", setPayRate)