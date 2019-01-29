#region Creating groups
# Global Security
New-ADGroup 'New Hires' -GroupCategory Security -GroupScope Global

# Verify
Get-ADGroup 'New Hires'

# Universal distribution
New-ADGroup 'HR Updates' -GroupCategory Distribution -GroupScope Universal

# Verify
Get-ADGroup 'HR Updates'

#endregion

#region Populating a group
# One user
Add-ADGroupMember 'New Hires' -Members 'Walter White'

# Verify
Get-ADGroupMember 'New Hires' | Format-Table Name

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