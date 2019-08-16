#region Detect lockouts
# Rather simple
$users = Search-ADAccount -LockedOut -UsersOnly

# Use Get-ADUserLockouts from the custom reports section, tracking lockouts
$lockouts = @()
ForEach($user in $users){
    $lockouts += Get-ADUserLockouts -Identity $user.SamAccountName | Sort-Object TimeStamp -Descending | Select-Object -First 1
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
Param (
    [string]$UserName,
    [DateTime]$TimeCreated
)
Get-SDAuthConfig -Silent
$ticketParams = @{
    Status = 'Open'
    Subject = "$UserName has been lockedout"
    FirstPost = "$UserName was lockedout at $TimeCreated"
}
New-SDTicket @ticketParams

#endregion
