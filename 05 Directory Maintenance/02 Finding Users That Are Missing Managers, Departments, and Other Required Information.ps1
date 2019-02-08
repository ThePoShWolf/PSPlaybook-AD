#region Filter for missing info
# Define needed info
$properties = 'Name','Department','Title'

# Find the users
$filterString = "($($properties[0]) -notlike '*')"
For($x=1;$x -lt $properties.count; $x++){
    $filterString += " -or ($($properties[$x]) -notlike '*')"
}
Get-ADUser -Filter $filterString -Properties $properties | Format-Table $properties

# Manager property
Get-ADUser -Filter * -Properties Manager | Where-Object Manager -eq $null | Format-Table Name,Manager

#endregion

#region Make it into a function
Function Get-ADUsersMissingInfo {
    [cmdletbinding()]
    Param (
        [string[]]$Properties = @('Name','Department','Title'),
        [switch]$IncludeManager
    )
    # Find the users
    $filterString = "($($properties[0]) -notlike '*')"
    For($x=1;$x -lt $properties.count; $x++){
        $filterString += " -or ($($properties[$x]) -notlike '*')"
    }
    Get-ADUser -Filter $filterString -Properties $properties | Format-Table $properties

    
}
#endregion