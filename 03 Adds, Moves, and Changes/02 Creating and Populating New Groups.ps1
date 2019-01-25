#region Creating groups
# Simple
New-ADGroup 'New Hires' -GroupCategory Security -GroupScope Global

# 

#endregion

#endregion Populating a group
# One user
Add-ADGroupMember 'New Hires' -Members 'Walter White'

# Verify
Get-ADGroupMember 'New Hires'

# Remove that user
Remove-ADGroupMember 'New Hires' -Members 'Walter White'

# Multiple Users
Add-ADGroupMember 'New Hires' -Members 'Walter White','Jesse.Pinkman'

# Add all users from a spreadsheet
$SpreadSheet = '.\UserUpdate.xlsx'
$Data = Import-Excel $SpreadSheet

$data | ForEach-Object {Add-ADGroupMember 'New Hires' -Members $_.'Full Name'.replace(' ','.')}

# Verify
Get-ADGroupMember 'New Hires' | Format-Table Name

# Manager group, current state
(Get-ADGroupMember 'Managers').Count

# Add users based on a filter
Get-ADUser -Filter {Title -like '*manager*'} -Properties Title | Format-Table Name,Title
Get-ADUser -Filter {Title -like '*manager*'} | ForEach-Object {Add-ADGroupMember 'Managers' -Members $_}

# Verify
(Get-ADGroupMember 'Managers').Count

#endregion