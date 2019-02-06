#region Define 'stale'
# Using Search-ADAccount
Search-ADAccount -AccountInactive -TimeSpan '90.00:00:00' -UsersOnly

# Info on the LastLogonDateTimeStamp: https://blogs.technet.microsoft.com/askds/2009/04/15/the-lastlogontimestamp-attribute-what-it-was-designed-for-and-how-it-works/

# If it is older than $LogonDate
$LogonDate = (Get-Date).AddDays(-90).ToFileTime()
Get-ADUser -Filter {LastLogonDateTimeStamp -lt $LogonDate}

# If it has value
Get-ADUser -Filter {LastLogonDateTimeStamp -notlike "*"}

# And if the account was created before $createdDate
$createdDate = (Get-Date).AddDays(-14).ToFileTime()
Get-ADUser -Filter {Created -lt $createdDate}

# Add them all together:
$filter = {
    ((LastLogonTimeStamp -lt $logonDate) -or (LastLogonTimeStamp -notlike "*"))
    -and (Created -lt $createdDate)
}
Get-ADuser -Filter $filter

#endregion

#region Functionize it
Function Get-ADStaleUsers {
    [cmdletbinding()]
    Param (
        [datetime]$NoLogonSince = (Get-Date).AddDays(-90),
        [datetime]$CreatedBefore = (Get-Date).AddDays(-14)
    )
    $NoLogonString = $NoLogonSince.ToFileTime()
    $filter = {
        ((LastLogonTimeStamp -lt $NoLogonString) -or (LastLogonTimeStamp -notlike "*"))
        -and (Created -lt $createdBefore)
    }
    $filter
    Get-ADuser -Filter $filter
}

# Usage
Get-ADStaleUsers

# Usage
Get-ADStaleUsers -NoLogonSince (Get-Date).AddDays(-30) -CreatedBefore (Get-Date).AddDays(-7) | Remove-ADUser -WhatIf

#endregion