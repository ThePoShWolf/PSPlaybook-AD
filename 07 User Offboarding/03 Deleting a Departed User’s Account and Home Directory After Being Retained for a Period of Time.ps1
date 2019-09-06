#region
# Retrieve the user to be deleted
$disabledOU = 'OU=Disabled,OU=People,DC=techsnipsdemo,DC=org'
$users = Get-ADUser -SearchBase $disabledOU -Filter * -Properties Description,HomeDirectory

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
        [int]$DaysDisabled = 30,
        [string]$disabledOU = 'OU=Disabled,OU=People,DC=techsnipsdemo,DC=org'
    )
    # Create the date
    $olderThan = (Get-Date).AddDays(-$DaysDisabled)
    # Take care of each account
    foreach ($user in (Get-ADUser -SearchBase $disabledOU -Filter * -Properties Description,HomeDirectory)) {
        # Check for the disabled date
        if($user.Description -match 'Disabled (?<disableDate>\d{1,2}\/\d{1,2}\/\d{4})$') {
            # If that date is older than the DaysDisabled
            if ([datetime]$Matches.disableDate -lt $olderThan) {
                # Remove the home directory
                if (Test-Path $user.HomeDirectory) {
                    Remove-Item $user.HomeDirectory -Recurse -Force
                }
                # and remove the user
                Remove-ADUser $user -Confirm:$false
            }
        }
    }
}

# Usage
Remove-ADDisabledUsers -DaysDisabled 0

#endregion