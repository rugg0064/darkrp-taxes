
-- Not qualified --
function taxSetFailNotQualifiedNotification()
    notification.AddLegacy("You cannot change the tax rate", NOTIFY_ERROR, 2)
    surface.PlaySound("buttons/button15.wav")
end
net.Receive("taxSetFailNotQualified", taxSetFailNotQualifiedNotification)

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
