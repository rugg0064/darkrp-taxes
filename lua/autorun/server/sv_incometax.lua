-- Config --
taxCfg = {}
taxCfg.defaultRate = 50
taxCfg.currentRate = 50

taxCfg.rateLimits = {}
taxCfg.rateLimits.min = 0
taxCfg.rateLimits.max = 100

local mayorID = nil
function setMayorID()
	mayorID = DarkRP.getJobByCommand("mayor").team
end
hook.Add("DarkRPFinishedLoading", "findMayorHook", setMayorID)

local function getAllCP()
	local cps = {}
	for i, e in ipairs(player.GetAll()) do
		if(e:isCP()) then
			table.insert(cps, e)
		end
	end
	return cps
end

local function setTaxesToDefault()
	taxCfg.currentRate = taxCfg.defaultRate
end

function jobChange(ply, before, after)
	if not mayorID then setMayorID() end
	beforeIsMayor = before==mayorID
	afterIsMayor = after==mayorID
	if(beforeIsMayor and !afterIsMayor) then
		setTaxesToDefault()
	end
end
hook.Add("OnPlayerChangedTeam", "taxJobChange", jobChange)

function removeOnDisconnect(ply)
	if(ply:isMayor()) then setTaxesToDefault() end
	removeFromPayable(ply)
end
hook.Add("PlayerDisconnected", "taxDisconnect", removeOnDisconnect)

local function taxPaymentFunc(ply, amnt)
	if(ply:isCP()) then
		local payAmnt = ply:resetTax()
		amnt = amnt + payAmnt
		if(payAmnt > 0) then
			return false, string.format("You have been paid $%d, $%d granted as tax collection", amnt, payAmnt), amnt
		else
			return false, string.format("You have been paid $%d", amnt), amnt
		end
	else
		taxAmnt = math.floor(amnt * taxCfg.currentRate/100)
		amnt = amnt - taxAmnt
		cps = getAllCP()
		cpCount = #cps
		for _, cp in ipairs(cps) do
			cp:addTax(taxAmnt / cpCount)
		end
		return false, string.format("You have been paid $%d, $%d taken as taxes", amnt, taxAmnt), amnt
	end
end
hook.Add("playerGetSalary", "taxSalary", taxPaymentFunc)

local meta = FindMetaTable("Player")
function meta:addTax(amnt)
	if(not self.taxBal) then self.taxBal = 0 end
	self.taxBal = self.taxBal + amnt
	return
end
function meta:resetTax()
	if(not self.taxBal) then self.taxBal = 0 end
	local temp = self.taxBal
	self.taxBal = 0
	return temp
end

util.AddNetworkString("taxSetFailNotQualified")
util.AddNetworkString("invalidCommand")
util.AddNetworkString("setTaxSucceed")

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

function setTaxRateChat(ply, text, teamChat)
	if(isDead) then sendError(ply) return false end
	if(string.sub(text, 0, 8) == "/taxrate") then
		setTaxRate(ply, "taxRate", {string.sub(text, 10)})
		return ""
	end
end
hook.Add("PlayerSay", "taxMenuCommand", setTaxRateChat)