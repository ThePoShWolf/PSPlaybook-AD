<#
    Install-Module ImportExcel
    Import-Module ActiveDirectory
#>

# Region prep work
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
#endregion

#region As a script
# Hashtable to correlate properties
$expectedProperties = @{
    Name = 'Full Name'
    GivenName = 'First Name'
    SurName = 'Last Name'
    Title = 'Job Title'
    Department = 'Department'
    OfficePhone = 'Phone Number'
}

# Incoming Directory
$dir = 'C:\Temp\IncomingUsers'

# For each spreadsheet it finds
ForEach($update in (Get-ChildItem $dir -Filter *.xlsx)){
    $data = Import-Excel $update.fullname
    ForEach($user in $data){
        # Build a splat
        $params = @{}
        ForEach($property in $expectedProperties.GetEnumerator()){
            # If the new user has the property
            If($user."$($property.value)".Length -gt 0){
                # Add it to the splat
                $params["$($property.Name)"] = $user."$($property.value)"
            }
        }
        # Deal with the manager value separate
        If($user.Manager.length -gt 0){
            $params['Manager'] = $user.Manager.Replace(' ','.')
        }
        # Create the user
        New-ADUser @params -WhatIf
    }
}
#endregion

#region Create a function
Function Import-UsersFromSpreadsheet {
    Param(
        [ValidatePattern('.*\.xlsx$')]
        [ValidateNotNullOrEmpty()]
        [string]$PathToSpreadsheet
    )
    # Hashtable to correlate properties
    $expectedProperties = @{
        Name = 'Full Name'
        GivenName = 'First Name'
        SurName = 'Last Name'
        Title = 'Job Title'
        Department = 'Department'
        OfficePhone = 'Phone Number'
    }
    # Make sure the xlsx exists
    If(Test-Path $PathToSpreadsheet){
        $data = Import-Excel $PathToSpreadsheet
        ForEach($user in $data){
            # Build a splat
            $params = @{}
            ForEach($property in $expectedProperties.GetEnumerator()){
                # If the new user has the property
                If($user."$($property.value)".Length -gt 0){
                    # Add it to the splat
                    $params["$($property.Name)"] = $user."$($property.value)"
                }
            }
            # Deal with the manager value separate
            If($user.Manager.length -gt 0){
                $params['Manager'] = $user.Manager.Replace(' ','.')
            }
            # Create the user
            New-ADUser @params -WhatIf
        }
    }
}
#endregion