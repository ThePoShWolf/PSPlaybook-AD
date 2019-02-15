#region The problem
Get-ADUser -Filter {OfficePhone -like '*'} -Properties OfficePhone | Select-Object Name,OfficePhone

# Decide on a format
# I'll be fancy: (XXX) XXX-XXXX

# Filter for numbers already like that
Get-ADuser -Filter {OfficePhone -like '(*) *-*'} -Properties OfficePhone | Format-Table Name,OfficePhone

# Changing phone numbers to the correct format:
$Examples = '1234567890','(123) 4567890','123-456-7890'

# Normalize
foreach ($n in $Examples){
    $n -replace '[^\d]',''
}

# Add the wanted syntax
foreach ($n in $Examples){
    $tmp = $n -replace '[^\d]',''
    "($($tmp.Substring(0,3))) $($tmp.Substring(3,3))-$($tmp.Substring(5,4))"
}

#endregion

#region Make the change to all users
$users = Get-ADUser -Filter {OfficePhone -notlike '(*) *-*'} -Properties OfficePhone
foreach ($user in $users){
    $tmp = $user.OfficePhone -replace '[^\d]',''
    $user.OfficePhone = "($($tmp.Substring(0,3))) $($tmp.Substring(3,3))-$($tmp.Substring(5,4))"
    Set-ADUser -Instance $user
}

# Verify
Get-ADuser -Filter {OfficePhone -like '(*) *-*'} -Properties OfficePhone | Format-Table Name,OfficePhone

#endregion