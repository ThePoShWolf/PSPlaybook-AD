#region Detect lockouts
# Rather simple
$users = Search-ADAccount -LockedOut -UsersOnly

# Use Get-ADUserLockouts from the custom reports section, tracking lockouts
ForEach($user in $users){
    $lockout = Get-ADUserLockouts -Identity $user.SamAccountName | Sort-Object TimeStamp -Descending | Select-Object -First 1
}

# Create a ticket
$ticketParams = @{
    Status = 'Open'
    Subject = "$($user.Name) has been lockedout"
    FirstPost = "$($user.Name) was lockedout at $($lockout.TimeStamp) from $($lockout.CallerComputer)"
}
New-SDTicket @ticketParams

#endregion

#region Make that run on a DC based off an event
Get-SDAuthConfig -Silent
$LockOutID = 4740
$event = Get-WinEvent -MaxEvents 1 -FilterHashtable @{
    LogName = 'Security'
    ID = $LockOutID
}
$ticketParams = @{
    Status = 'Open'
    Subject = "$($event.Properties[0].Value) has been lockedout"
    FirstPost = "$($event.Properties[0].Value) was lockedout at $($event.TimeCreated) from $($event.Properties[1].Value)"
}
New-SDTicket @ticketParams

#endregion
