#region
# Disable a user account
$user = Get-ADUser 'Jesse.Pinkman'
Disable-ADAccount $user

# Tag the description
Set-ADUser $user -Description "$($user.Description) - Disabled $((Get-Date).ToShortDateString())"

# Retain it
Move-ADObject -Identity $user.DistinguishedName -TargetPath "DisabledOU"
#endregion

#region Of course make that a function!
Function Invoke-UserOffboarding {
    Param (
        [Parameter(
            ValueFromPipeline = $true,
            Mandatory = $true
        )]
        [Microsoft.ActiveDirectory.Management.ADUser]$Identity,
        [string]$DisabledOU = "DisabledOU"
    )
    $user = Get-ADUser $Identity
    Disable-ADAccount $user
    Set-ADUser $user -Description "$($user.Description) - Disabled $((Get-Date).ToShortDateString())"
    Move-ADObject -Identity $user.DistinguishedName -TargetPath $DisabledOU
}
#endregion