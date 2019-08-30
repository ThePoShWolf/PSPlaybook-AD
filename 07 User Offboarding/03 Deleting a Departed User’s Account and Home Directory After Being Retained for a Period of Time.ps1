#region
# Retrieve the user to be deleted
$disabledOU = 'OU=Disabled,OU=People,DC=techsnipsdemo,DC=org'
$users = Get-ADUser -SearchBase $disabledOU -Filter * -Properties Description

# Figure out when it was disabled
foreach ($user in $users) {
    $user.Description
}

# Regex match the date out of there
foreach($user in $users) {
    if($user.Description -match 'Disabled (?<disableDate>\d{1,2}\/\d{1,2}\/\d{4})$') {
        $Matches.disableDate
    }
}

# Remove the home directory
foreach ($user in $users) {
    if(Test-Path $user.HomeDirectory){
        Remove-Item $user.HomeDirectory -Recurse -Force
    }
}

# Remove the user
foreach ($user in $users) {
    Remove-ADUser $user
}
#endregion

#region fix
New-ADUser -Name 'Jesse Pinkman' -SamAccountName jesse.pinkman -Path 'OU=People,DC=techsnipsdemo,DC=org' -Description 'Partner' -HomeDirectory '\\dc01\Share\Users\jesse.pinkman'
New-Item '\\dc01\Share\Users\jesse.pinkman' -ItemType Directory
Invoke-ADUserOffboarding jesse.pinkman
#endregion

#region Its a bird, its a plane, no its a PowerShell function!!!
Function Remove-ADDisabledUsers {
    param (
        [string]$disabledOU = 'OU=Disabled,OU=People,DC=techsnipsdemo,DC=org',
        [int]$DaysOld = 30
    )
    $olderThan = (Get-Date).AddDays(-30)
    foreach ($user in (Get-ADUser -SearchBase $disabledOU -Filter * -Properties HomeDirectory)) {
        if($user.Description -match 'Disabled (?<disableDate>\d{1,2}\/\d{1,2}\/\d{4})$') {
            if ([datetime]$Matches.disableDate -lt $olderThan) {
                if (Test-Path $user.HomeDirectory) {
                    Remove-Item $user.HomeDirectory -Recurse -Force
                }
                Remove-ADUser $user -Confirm:$false
            }
        }
    }
}

#endregion