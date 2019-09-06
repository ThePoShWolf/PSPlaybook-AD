#region
# Splitting strings
'email@domain.com'.Split('@')
'email@domain.com'.Split('@')[1]

# Find all UPN domains currently used:
(Get-ADUser -Filter *).UserPrincipalName | %{$_.split('@')[1]} | Select -Unique

# Fild all email domains currently used (according to AD):
(Get-ADUser -Filter * -Properties EmailAddress).EmailAddress | %{$_.split('@')[1]} | Select -Unique

# Check if the user's email starts with their SamAccountName
(Get-ADUser -Filter * -Properties EmailAddress) | %{
    if ($_.EmailAddress -notlike "$($_.SamAccountName)*") {
        "$($_.SamAccountName) - $($_.EmailAddress)"
    }
}

# Make a quick backup, just in case
Get-ADUser -Filter * -Properties EmailAddress | Select-Object SamAccountName,UserPrincipalName,EmailAddress | Export-Csv .\UpnBackup.csv -NoTypeInformation -Force

# So we'll just use the email address as the UPN, keep it simple
Get-ADUser -Filter * -Properties EmailAddress | %{
    Set-ADUser $_ -UserPrincipalName $_.EmailAddress
}

# Now we can check the UPN domains again
(Get-ADUser -Filter *).UserPrincipalName | %{$_.split('@')[1]} | Select -Unique

#endregion

#region fix
Get-ADUser -Filter * | %{
    Set-ADUser $_ -UserPrincipalName "$($_.SamAccountName)@techsnipsdemo.local"
}
#endregion

#region Is that too simple for a function?
#region Spoiler alert
# No
#endregion
#region
Function Update-ADUsersUPN {
    Param (
        [string]$EmailDomain = 'techsnipsdemo.org'
    )
    $users = Get-ADUser -Filter {UserPrincipalName -notlike "*$EmailDomain"} -Properties EmailAddress
    foreach ($user in $users) {
        Set-ADUser $user -UserPrincipalName $user.EmailAddress
    }
}

# Usage
Update-ADUsersUPN
#endregion
#endregion 