<#
    Install-Module ImportExcel
    Import-Module ActiveDirectory
#>

# Import the spreadsheet
$SpreadSheet = '.\UserUpdate.xlsx'
$Data = Import-Excel $SpreadSheet

# Check the data
$Data | Format-Table

# Correlate fields
$Params = @{
    Name = $Data[0].'Full Name'
    GivenName = $Data[0].'First Name'
    SurName = $Data[0].'Last Name'
    Title = $Data[0].'Job Title'
    Department = $Data[0].Department
    OfficePhone = $Data[0].'Phone Number'
}

# Correlate 'Manager' field
Help Set-ADUser -Parameter Manager

<# <ADUser> can be:
    SamAccountName
    DistinguishedName
    GUID
    SID
#>

Get-ADUser $Data[0].Manager

Get-ADUser $Data[0].Manager.Replace(' ','.')

# Full correlation
$Params = @{
    Name = $Data[0].'Full Name'
    GivenName = $Data[0].'First Name'
    SurName = $Data[0].'Last Name'
    Title = $Data[0].'Job Title'
    Department = $Data[0].Department
    OfficePhone = $Data[0].'Phone Number'
    Manager = $Data[0].Manager.Replace(' ','.')
}