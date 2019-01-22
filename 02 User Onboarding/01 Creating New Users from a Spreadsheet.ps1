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

#region Create a function
Function Import-ADUsersFromSpreadsheet {
    [cmdletbinding()]
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
            # Deal with other values
            If($user.Manager.length -gt 0){
                $params['Manager'] = $user.Manager.Replace(' ','.')
            }
            $params['SamAccountName'] = "$($user.$($expectedProperties['GivenName'])).$($user.$($expectedProperties['SurName']))"
            # Create the user
            New-ADUser @params
        }
    }
}

# Verify
ForEach($user in $data){
    Get-ADUser "$($user.'First Name').$($user.'Last Name')" | Select-Object Name
}
#endregion