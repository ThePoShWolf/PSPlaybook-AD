#region Sort OUs with GPO links by whether or not they have non-OU children

# Get all OUs with GPO links:
Get-ADOrganizationalUnit -Filter {LinkedGroupPolicyObjects -like "*"} | Format-Table Name

# For each OU, we need to:
Get-ADObject -Filter {ObjectClass -ne 'OrganizationalUnit'} <#-SearchBase $OU#>

# Loop through them all
ForEach($OU in Get-ADOrganizationalUnit -Filter {LinkedGroupPolicyObjects -like "*"}){
    $objects = $null
    $objects = Get-ADObject -Filter {ObjectClass -ne 'OrganizationalUnit'} -SearchBase $OU
    If($objects){
        [pscustomobject]@{
            OU = $OU
            Empty = $false
        }
    }Else{
        [pscustomobject]@{
            OU = $OU
            Empty = $true
        }
    }
}

#endregion

#region Yes, functionize that please
Function Get-ADOrganizationalUnitStatus {
    param (

    )
    ForEach($OU in Get-ADOrganizationalUnit -Filter {LinkedGroupPolicyObjects -like "*"}){
        $objects = $null
        $objects = Get-ADObject -Filter {ObjectClass -ne 'OrganizationalUnit'} -SearchBase $OU
        If($objects){
            [pscustomobject]@{
                OU = $OU
                Empty = $false
            }
        }Else{
            [pscustomobject]@{
                OU = $OU
                Empty = $true
            }
        }
    }
}

# Usage
Get-ADOrganizationalUnitStatus

#endregion

#region Find GPOs linked to those empty OUs

# Store the OU status in a variable
$emptyOUs = Get-ADOrganizationalUnitStatus | Where-Object Empty

# Get the linked GPO Guids
$emptyOUs[0].OU.LinkedGroupPolicyObjects

# Convert it to a GPO
$emptyOUs[0].OU.LinkedGroupPolicyObjects.Substring(4,36)
Get-GPO -Guid $emptyOUs[0].LinkedGroupPolicyObjects.Substring(4,36)

# Object to build output
$GPOsLinkedToEmptyOUs = @()

ForEach($OU in $emptyOUs.OU){
    ForEach($GPOGuid in $OU.LinkedGroupPolicyObjects){
        $GPO = Get-GPO -Guid $GPOGuid.Substring(4,36)
        Write-Host "GPO: '$($GPO.DisplayName)' is linked to empty OU: $($OU.Name)"
        If($GPOsLinkedToEmptyOUs.GPOId -contains $GPO.Id){
            ForEach($LinkedGPO in ($GPOsLinkedToEmptyOUs | Where-Object {$_.GPOId -eq $GPO.Id})){
                $LinkedGPO.EmptyOU = [string[]]$LinkedGPO.EmptyOU + "$($OU.DistinguishedName)"
            }
        }Else{
            $GPOsLinkedToEmptyOUs += [PSCustomObject]@{
                GPOName = $GPO.DisplayName
                GPOId = $GPO.Id
                EmptyOU = $OU.DistinguishedName
                NonEmptyOU = ''
            }
        }
    }
}

#result
$GPOsLinkedToEmptyOUs | Format-List

#endregion

#region Check if those GPOs are linked to any OUs with children

ForEach($OU in $nonEmptyOUs){
    ForEach($GPO in $GPOsLinkedToEmptyOUs){
        If($OU.LinkedGroupPolicyObjects.Substring(4,36) -contains $GPO.GPOId){
            Write-Host "GPO: '$($GPO.GPOName)' also linked to non-empty OU: $($OU.Name)"
            If($GPO.NonEmptyOU){
                $GPO.NonEmptyOU = [string[]]$GPO.NonEmptyOU + $OU.DistinguishedName
            }Else{
                $GPO.NonEmptyOU = $OU.DistinguishedName
            }
        }
    }
}

#Now
$GPOsLinkedToEmptyOUs | Format-List

#endregion

#region Bring it all together into a function with useful output

Function Get-GPOsLinkedToEmptyOUs{
    [cmdletbinding()]
    Param()
    Function Get-ADOrganizationalUnitStatus {
        param (
    
        )
        ForEach($OU in Get-ADOrganizationalUnit -Filter {LinkedGroupPolicyObjects -like "*"}){
            $objects = $null
            $objects = Get-ADObject -Filter {ObjectClass -ne 'OrganizationalUnit'} -SearchBase $OU
            If($objects){
                [pscustomobject]@{
                    OU = $OU
                    Empty = $false
                }
            }Else{
                [pscustomobject]@{
                    OU = $OU
                    Empty = $true
                }
            }
        }
    }
    $OUs = Get-ADOrganizationalUnitStatus
    $GPOsLinkedToEmptyOUs = @()
    ForEach($OU in ($OUs | Where-Object {$_.empty}).OU){
        ForEach($GPOGuid in $OU.LinkedGroupPolicyObjects){
            $GPO = Get-GPO -Guid $GPOGuid.Substring(4,36)
            Write-Verbose "GPO: '$($GPO.DisplayName)' is linked to empty OU: $($OU.Name)"
            If($GPOsLinkedToEmptyOUs.GPOId -contains $GPO.Id){
                ForEach($LinkedGPO in ($GPOsLinkedToEmptyOUs | Where-Object {$_.GPOId -eq $GPO.Id})){
                    $LinkedGPO.EmptyOU = [string[]]$LinkedGPO.EmptyOU + "$($OU.DistinguishedName)"
                }
            }Else{
                $GPOsLinkedToEmptyOUs += [PSCustomObject]@{
                    GPOName = $GPO.DisplayName
                    GPOId = $GPO.Id
                    EmptyOU = $OU.DistinguishedName
                    NonEmptyOU = ''
                }
            }
        }
    }
    ForEach($OU in ($OUs | Where-Object {-not $_.empty}).OU){
        ForEach($GPO in $GPOsLinkedToEmptyOUs){
            If($OU.LinkedGroupPolicyObjects.Substring(4,36) -contains $GPO.GPOId){
                Write-Verbose "GPO: '$($GPO.GPOName)' also linked to non-empty OU: $($OU.Name)"
                If($GPO.NonEmptyOU){
                    $GPO.NonEmptyOU = [string[]]$GPO.NonEmptyOU + $OU.DistinguishedName
                }Else{
                    $GPO.NonEmptyOU = $OU.DistinguishedName
                }
            }
        }
    }
    $GPOsLinkedToEmptyOUs
}

# Usage
Get-GPOsLinkedToEmptyOUs

# Finding unused GPOs
Get-GPOsLinkedToEmptyOUs | Where-Object {$_.EmpyOU -and -not $_.NonEmptyOU}

#endregion