local taxCfg = {}
taxCfg.defaultRate = 0.5
taxCfg.currentRate = 0.5
taxCfg.mayorPay = 25
taxCfg.chiefPay = 25
taxCfg.policePay = 50
taxCfg.mayorNames = {"Mayor"}
taxCfg.chiefNames = {"Civil Protection Chief"}
taxCfg.policeNames = {"Civil Protection"}

local meta = FindMetaTable("Player")

function meta:addTax(amnt)
	if not self.taxBal then self.taxBal = 0 end

	self.taxBal = self.taxBal + amnt
	return
end
function meta:resetTax(amnt)
	if not self.taxBal then self.taxBal = 0 end
	local temp = self.taxBal
	self.taxBal = 0
	return temp
end

hook.Add("playerGetSalary", "taxSalary", function(ply, amnt)
	--[[
	print(ply:getJobTable().name)
	--print(ply:getJobTable().category)
	--print(ply:getJobTable().team)
	for key,value in pairs(ply:getJobTable()) do
		print("found member " .. key);
	end
	]]--
	
	if(ply:getJobTable().category == "Civil Protection") then
		local taxAmnt = ply:resetTax()
		amnt = amnt + taxAmnt
		return false, string.format("You have been paid $%d, $%d given as tax collection", amnt, taxAmnt), amnt
	end

	local taxAmnt = amnt * taxCfg.currentRate
	taxAmnt = math.floor(taxAmnt)
	amnt = amnt - taxAmnt
	local ptMultiplier = 100/(taxCfg.mayorPay + taxCfg.chiefPay + taxCfg.policePay)
	local mayor = {}
	local chief = {}
	local police = {}
	for i, ply2 in ipairs(player.GetAll()) do
		local plyJob = ply2:getJobTable()
		local jobName = plyJob.name

		for _, str in ipairs(taxCfg.mayorNames) do
			if(str == jobName) then
				table.insert(mayor, ply2)
				goto outercontinue
			end
		end

		for _, str in ipairs(taxCfg.chiefNames) do
			if(str == jobName) then
				table.insert(chief, ply2)
				goto outercontinue
			end
		end

		for _, str in ipairs(taxCfg.policeNames) do
			if(str == jobName) then
				table.insert(police, ply2)
				goto outercontinue
			end
		end
		::outercontinue::
	end

	if((#mayor + #chief + #police) > 0) then
		local ptTotal = ((#mayor)*taxCfg.mayorPay) + ((#chief)*taxCfg.chiefPay) + ((#police)*taxCfg.policePay)
		local ptValue = taxAmnt/ptTotal
		for _, ply2 in ipairs(mayor) do
			print("adding tax for")
			print(ptMultiplier * taxCfg.mayorPay * ptValue)
			ply2:addTax(ptMultiplier * taxCfg.mayorPay * ptValue)
		end
		for _, ply2 in ipairs(chief) do
			ply2:addTax(ptMultiplier * taxCfg.chiefPay * ptValue)
		end
		for _, ply2 in ipairs(police) do
			ply2:addTax(ptMultiplier * taxCfg.policePay * ptValue)
		end
	end
	return false, string.format("You have been paid $%d, $%d taken as taxes", amnt, taxAmnt), amnt
end)
