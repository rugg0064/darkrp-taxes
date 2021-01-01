function taxSetFailNotQualifiedNotification()
    notification.AddLegacy("You cannot change the tax rate", NOTIFY_ERROR, 2)
    surface.PlaySound("buttons/button15.wav")
end
net.Receive("taxSetFailNotQualified", taxSetFailNotQualifiedNotification)

function invalidCommandNotification()
    print("Invalid input")
    notification.AddLegacy("Invalid input", NOTIFY_ERROR, 2)
    surface.PlaySound("buttons/button15.wav")
end
net.Receive("invalidCommand", invalidCommandNotification)

function setTaxSucceedNotification()
	local value = net.ReadDouble()
    local string = string.format("Tax set to %.0f%%", value)
	notification.AddLegacy(string, NOTIFY_GENERIC, 2)
    surface.PlaySound("buttons/button15.wav")
end
net.Receive("setTaxSucceed", setTaxSucceedNotification)