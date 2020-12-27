local TAX_MENU_HTML = [[
	<!DOCTYPE html>
	<html lang="en">
	<meta charset="UTF-8">
	<title>Government Finances</title>
		<style>
			*{
				background-color: white;
				font-size:20px;
			}
			h1{
				font-size:40px;
			}
			p{
				font-size:20px;
			}
			table{
				background-color:coral;
				border-radius: 5px;
			}
			table, th, td {
				border: 2px solid black;
			}
			td.value{
				width:60px;
			}
			button{
				border-radius :15px;
				background-color:lightblue;
			}
		</style>
					
		<script>
			let employeeStrings = []
			
			function buildTable()
			{
				deleteTableChildrenExceptTax()
				var payrollSlider = document.getElementById('flatTaxSlider')
				payrollSlider.value = 0
				payrollChange(payrollSlider)
				var table = document.getElementById('mainTable')
				for(var i = 0; i < employeeStrings.length; i++)
				{
					var row = document.createElement('tr')
					table.appendChild(row)
	
					var textCol = document.createElement('td')
					textCol.innerHTML = employeeStrings[i]
					row.appendChild(textCol)
	
					var sliderString = employeeStrings[i] + 'slider'
					var sliderCol = document.createElement('td')
					var slider = document.createElement('input')
					slider.type = 'range'
					slider.id = sliderString
					slider.value = 0
					row.appendChild(sliderCol)
					sliderCol.appendChild(slider)
	
					let valueString = employeeStrings[i] + 'PayValue'
					var valueCol = document.createElement('td')
					valueCol.id = valueString
					valueCol.innerHTML = '0%'
					row.appendChild(valueCol)
	
					slider.oninput = function() {
						document.getElementById(valueString).innerHTML = this.value + '%'
					}
				}
			}
	
			function init()
			{
				buildTable()
			}
	
			function payrollChange(slider)
			{
				document.getElementById('payrollTaxValue').innerHTML = slider.value + '%'
			}
	
			function setButton()
			{
				params = [document.getElementById("flatTaxSlider").value]
				for(var i = 0; i < employeeStrings.length; i++)
				{
					value = document.getElementById(employeeStrings[i] + 'slider').value
					params.push(value)
				}
				lua.setFunction(params)
			}
	
			function redrawButton()
			{
				lua.redraw()
			}
	
			function deleteTableChildrenExceptTax()
			{
				var children = document.getElementById('mainTable').childNodes
				
				for(var i = children.length - 1; i != 1; i--)
				{
					children[i].remove()
				}
			}
	
			function setEmployeeIDs(arr)
			{
				employeeStrings = []
				for(var i = 0; i < arr.length; i++)
				{
					employeeStrings.push(arr[i])
				}
				init()
			}
		</script>
	
		<body onload='init();'>
			<div>
				<h1>Tax configuration</h1>
				<p>Here you can set different rates for taxes and employee compensation.</p>
				<table id='mainTable'>
					<tr>
						<td>Payroll tax</td>
						<td><input type='range' min='0' max='100' value='0' class='slider' id='flatTaxSlider' oninput='payrollChange(this)'></td>
						<td class='value' id='payrollTaxValue'>0%</td>
					</tr>
				</table>
			</div>
			<button onclick='redrawButton();'>Reset</button>
			<button onclick='setButton();'>Set</button>
			<span style='font-size:12px'>setting higher than a total of 100% will scale to match a total of 100</span>
		</body>
			</html>
]]

-- Not qualified --
function taxSetFailNotQualifiedNotification()
    notification.AddLegacy("You cannot change the tax rate", NOTIFY_ERROR, 2)
    surface.PlaySound("buttons/button15.wav")
end
net.Receive("taxSetFailNotQualified", taxSetFailNotQualifiedNotification)
function taxSetFailNotQualifiedNotification()
    notification.AddLegacy("You cannot change the pay rate", NOTIFY_ERROR, 2)
    surface.PlaySound("buttons/button15.wav")
end
net.Receive("jobSetFailNotQualified", taxSetFailNotQualifiedNotification)

-- Error --
function invalidCommandNotification()
    print("Invalid input")
    notification.AddLegacy("Invalid input", NOTIFY_ERROR, 2)
    surface.PlaySound("buttons/button15.wav")
end
net.Receive("invalidCommand", invalidCommandNotification)

-- Rate Set Successfully--
function setTaxSucceedNotification()
    local value = net.ReadDouble()
    local string = string.format("Tax set to %f", value)
    print(string)
    notification.AddLegacy(string, NOTIFY_GENERIC, 2)
    surface.PlaySound("buttons/button15.wav")
end
net.Receive("setTaxSucceed", setTaxSucceedNotification)

-- Rate Set Successfully--
function setPaySucceedNotification()
    local role = net.ReadString()
    local value = net.ReadDouble()
    local string = string.format("Pay for %s set to %f", role, value)
    print(string)
    notification.AddLegacy(string, NOTIFY_GENERIC, 2)
    surface.PlaySound("buttons/button15.wav")
end
net.Receive("setPaySucceed", setPaySucceedNotification)

function recievePayingRoles()
	local amnt = net.ReadInt(8)
	if not roles then roles = {} end
	roles = {}
	for i=1, amnt do
		table.insert(roles, net.ReadString())
	end
end
net.Receive("sendPayingRoles", recievePayingRoles)

function askForPayingRoles()
	net.Start("askPayingRoles")
	net.SendToServer()
end

function setTaxesAndPays(str)
	for i, e in ipairs(str) do
		print(i,e)
        if(i == 1) then
            RunConsoleCommand("taxrate", e/100)
        else
            RunConsoleCommand("payRate", i-1    , e)
        end
    end
end
	
function redrawHTMLMayorMenu(html)
	askForPayingRoles()
	local setString = "setEmployeeIDs(["
	if not roles then askForPayingRoles() return end
	for i, e in ipairs(roles) do
		print(i,e)
		setString = setString .. "'" .. e .. "'"
		if(i != #roles) then 
			setString = setString .. ", "
		end
	end
	setString = setString .. "]);"
	print(setString)
	html:QueueJavascript(setString)
end

function createMayorMenu()
	if(LocalPlayer():isMayor()) then
		askForPayingRoles()
		local DFrame = vgui.Create("DFrame")
		DFrame:SetSize(400, 450)
		DFrame:Center()
		DFrame:SetTitle("Mayor Menu") 		
		DFrame:MakePopup()

		local html = vgui.Create("DHTML", DFrame)
		html:Dock(FILL)
		html:SetHTML(TAX_MENU_HTML)
		html:SetAllowLua(true)
		html:AddFunction("lua", "setFunction", setTaxesAndPays)
		html:AddFunction("lua", "redraw", function() redrawHTMLMayorMenu(html) end)
		redrawHTMLMayorMenu(html)
	end
end
concommand.Add("taxmenu", createMayorMenu)