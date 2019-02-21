#region The problem
Get-ADUser -Filter {OfficePhone -like '*'} -Properties OfficePhone | Select-Object Name,OfficePhone

#region Resolve it with PowerShell
# Decide on a format
# I'll be fancy: (XXX) XXX-XXXX

# Filter for numbers already like that
Get-ADuser -Filter {OfficePhone -like '(*) *-*'} -Properties OfficePhone | Format-Table Name,OfficePhone

# Changing phone numbers to the correct format:
$Examples = '1234567890','(123) 4567890','123-456-7890'

# Normalize
foreach ($num in $Examples){
    $num -replace '[^\d]',''
}

# Add the wanted syntax
foreach ($num in $Examples){
    $tmp = $num -replace '[^\d]',''
    If($tmp.Length -eq 10){
        "($($tmp.Substring(0,3))) $($tmp.Substring(3,3))-$($tmp.Substring(6,4))"
    }Else{
        Write-Host 'Invalid number'
    }
}
#endregion
#endregion

#region Make the change to all users
$users = Get-ADUser -Filter {OfficePhone -notlike '(*) *-*'} -Properties OfficePhone
foreach ($user in $users){
    $tmp = $user.OfficePhone -replace '[^\d]',''
    $user.OfficePhone = "($($tmp.Substring(0,3))) $($tmp.Substring(3,3))-$($tmp.Substring(6,4))"
    Set-ADUser -Instance $user
}

# Verify
Get-ADuser -Filter {OfficePhone -like '(*) *-*'} -Properties OfficePhone | Format-Table Name,OfficePhone

#endregion