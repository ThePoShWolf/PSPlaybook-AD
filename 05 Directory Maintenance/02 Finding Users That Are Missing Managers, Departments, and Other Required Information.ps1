#region Filter for missing info
# Define needed info
$properties = 'Name','Department','Title'

# Build a filter
$filterString = "($($properties[0]) -notlike '*')"
For($x=1;$x -lt $properties.count; $x++){
    $filterString += " -or ($($properties[$x]) -notlike '*')"
}
$filterString

# Get those users
Get-ADUser -Filter $filterString -Properties $properties | Format-Table $properties

# Manager property
Get-ADUser -LDAPFilter "(!manager=*)" -Properties Manager | Format-Table Name,Manager

# Combine both into an LDAP filter
$properties += 'Manager'
$ldapFilter = "(|(!$($properties[0])=*)"
For($x=1;$x -lt $properties.count; $x++){
    $ldapFilter += "(!$($properties[$x])=*)"
}
$ldapFilter += ')'
Get-ADUser -LDAPFilter $ldapFilter -Properties $properties | Format-Table $properties

# One issue with using an LDAP filter
Get-ADUser -LDAPFilter '(!surname=*)'
Get-ADUser -LDAPFilter '(!sn=*)'

# Build a hashtable of values
# https://stackoverflow.com/questions/41447372/is-there-a-complete-list-of-active-directory-attributes-and-a-mapping-to-ldap
$ADAssembly = [Microsoft.ActiveDirectory.Management.ADEntity].Assembly
$LDAPAttributes = $ADAssembly.GetType('Microsoft.ActiveDirectory.Management.Commands.LdapAttributes')
$LDAPNameConstants = $LDAPAttributes.GetFields('Static,NonPublic') | Where-Object {$_.IsLiteral}
$LDAPPropertyMap = @{}
$LDAPNameConstants | ForEach-Object {
    $LDAPPropertyMap[$_.Name] = $_.GetRawConstantValue()
}

# Now
$LDAPPropertyMap['SurName']

# New filter
$ldapFilter = "(|(!$($LDAPPropertyMap[$properties[0]])=*)"
For($x=1;$x -lt $properties.count; $x++){
    $ldapFilter += "(!$($LDAPPropertyMap[$properties[$x]])=*)"
}
$ldapFilter += ')'
Get-ADUser -LDAPFilter $ldapFilter -Properties $properties | Format-Table $properties

# Compare that to Where-Object
Measure-Command {
    Get-ADUser -LDAPFilter $ldapFilter -Properties $properties
}

Measure-Command {
    Get-ADUser -Filter * -Properties $properties | Where-Object {
        -not $_.Name -or
        -not $_.Department -or
        -not $_.Title -or
        -not $_.Manager
    }
}

#endregion

#region Make it into a function
Function Get-ADUsersMissingInfo {
    [cmdletbinding()]
    Param (
        [string[]]$Properties = @('Name','Department','Title','Manager')
    )
    # Build our property map
    $ADAssembly = [Microsoft.ActiveDirectory.Management.ADEntity].Assembly
    $LDAPAttributes = $ADAssembly.GetType('Microsoft.ActiveDirectory.Management.Commands.LdapAttributes')
    $LDAPNameConstants = $LDAPAttributes.GetFields('Static,NonPublic') | Where-Object {$_.IsLiteral}
    $LDAPPropertyMap = @{}
    $LDAPNameConstants | ForEach-Object {
        $LDAPPropertyMap[$_.Name] = $_.GetRawConstantValue()
    }

    # Find the users
    $ldapFilter = "(|(!$($LDAPPropertyMap[$properties[0]])=*)"
    For($x=1;$x -lt $properties.count; $x++){
        $ldapFilter += "(!$($LDAPPropertyMap[$properties[$x]])=*)"
    }
    $ldapFilter += ')'
    Get-ADUser -LDAPFilter $ldapFilter -Properties $properties
}

# Usage
Get-ADUsersMissingInfo

# Custom
Get-ADUsersMissingInfo -Properties OfficePhone

# Create an Excel sheet
$exportExcelParams = @{
    Autosize = $true
    TableName = 'Props'
    TableStyle = 'Light1'
}
Get-ADUsersMissingInfo | Export-Excel .\MissingProperties.xlsx -Title 'Missing Properties' @exportExcelParams

Import-Excel .\MissingProperties.xlsx -StartRow 2

#endregion