
local taxCfg = {}
-- Config --
taxCfg.defaultRate = 0.5
taxCfg.currentRate = 0.5

taxCfg.rateLimits = {}
taxCfg.rateLimits.min = 0
taxCfg.rateLimits.max = 1

taxCfg.pays = { 
   --Group name, current rate, default rate, {Job titles}, {Job ids}
	{"Mayor", 25, 25, {"Mayor"}, {7}},
	{"Chief", 25, 25, {"Civil Protection Chief"}, {6}},
	{"Civil Protection", 50, 50, {"Civil Protection"}, {2}}
}
local payable = {}

local function setTaxesToDefault()
	print("setting")
	taxCfg.currentRate = taxCfg.defaultRate
	for _, paytable in ipairs(taxCfg.pays) do
		paytable[2] = paytable[3]
	end
end

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
		for _, id in ipairs(payTable[5]) do
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
	print("changing")
	beforeIsMayor = false
	afterIsMayor = false
	for _, payTable in ipairs(taxCfg.pays) do
		if(payTable[1] == "Mayor") then
			for _, n in ipairs(payTable[5]) do
				print(n)
				if(before == n) then beforeIsMayor = true end
				if(after == n) then afterIsMayor = true end
			break
			end
		end
	end
	print(beforeIsMayor, afterIsMayor)
	if(beforeIsMayor and !afterIsMayor) then setTaxesToDefault() end

	afterPay = jobIDGetsPayed(after)
	removeFromPayable(ply)
	if(afterPay) then table.insert(payable, ply) end
	print(#payable)
	for i, ply2 in ipairs(payable) do
		print(i, ply2)
	end
end
hook.Add("OnPlayerChangedTeam", "taxJobChange", jobChange)

function removeOnDisconnect(ply)
	removeFromPayable(ply)
end
hook.Add("PlayerDisconnected", "taxDisconnect", removeOnDisconnect)

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
	
	local payouts = {}
	for _, ply2 in ipairs(player.GetAll()) do
		local plyJob = ply2:getJobTable()
		local jobName = plyJob.name
		for _, payTable in ipairs(taxCfg.pays) do
			for _, jobStr in ipairs(payTable[4]) do
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
		if(ptTotal > 0) then
			local ptValue = taxAmnt/ptTotal
			for _, payout in ipairs(payouts) do
				local ply2 = payout[1]
				local payTable = payout[2]
				ply2:addTax(ptValue * payTable[2])
			end
		end
	end
	return false, string.format("You have been paid $%d, $%d taken as taxes", amnt, taxAmnt), amnt
end
hook.Add("playerGetSalary", "taxSalary", taxPaymentFunc)

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

util.AddNetworkString("taxSetFailNotQualified")
util.AddNetworkString("jobSetFailNotQualified")
util.AddNetworkString("invalidCommand")
util.AddNetworkString("setTaxSucceed")
util.AddNetworkString("setPaySucceed")
util.AddNetworkString("sendPayingRoles")
util.AddNetworkString("askPayingRoles")

function sendError(ply)
	net.Start("invalidCommand") 
	net.Send(ply) 
	return
end

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

function sendPayingRoles(ply)
	net.Start("sendPayingRoles")
	net.WriteInt(#taxCfg.pays, 8)
	for _, v in ipairs(taxCfg.pays) do
		net.WriteString(v[1])
	end
	net.Send(ply)
end
net.Receive("askPayingRoles", function(len, ply) sendPayingRoles(ply) end)

function setPayRate(ply, cmd, args)
	if(!ply:isMayor()) then 
		net.Start("jobSetFailNotQualified") 
		net.Send(ply) 
		return 
	end
	
	if(#args < 2) then sendError(ply) return end

	value = tonumber(args[2])
	if not value then sendError(ply) return end

	index = tonumber(args[1])
	if(index) then
		payTable = taxCfg.pays[index]
		payTable[2] = value
		net.Start("setPaySucceed")
		net.WriteString(payTable[1])
		net.WriteDouble(value)
		net.Send(ply)
		return
	else
		for _, payTable in ipairs(taxCfg.pays) do
			if(payTable[1] == args[1]) then
				payTable[2] = value
				net.Start("setPaySucceed")
				net.WriteString(payTable[1])
				net.WriteDouble(value)
				net.Send(ply)
				return
			end
		end
	sendError(ply) 
	end
	return
end
concommand.Add("payRate", setPayRate)