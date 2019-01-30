#region Retrieving data
# Source
$baseuri = 'http://techsnips_hr.io'
$resource = 'employees'

# Get data
Invoke-RestMethod $baseuri/$resource -Method Get

# Get a single employee
Invoke-RestMethod $baseuri/$resource/606 -Method Get

# Compare them to AD
$user = Invoke-RestMethod $baseuri/$resource/606 -Method Get
Get-ADUser "$($user.first_name).$($user.last_name)"

# You should track API IDs somehow
Get-ADUser -Filter "Description -eq $($user.id)" -Properties Description | Format-Table Name,Description

# Assign it to a variable
$adUser = Get-ADUser -Filter "Description -eq $($user.id)" -Properties Title,OfficePhone,Manager,Department,Description

# Side by side
[pscustomobject]@{
    $user.full_name = $adUser.name
    $user.first_name = $aduser.givenname
    $user.last_name = $adUser.surname
    $user.job_title = $aduser.title
    $user.phone = $aduser.officephone
    $user.manager = $aduser.manager
    $user.department = $aduser.department
}
#endregion

#region Update Changes
# Create a property ht
$expectedProperties = @{
    Name = 'full_name'
    GivenName = 'first_name'
    SurName = 'last_name'
    Title = 'job_title'
    OfficePhone = 'phone'
}

# Build a splat
$splat = @{
    Identity = (Get-ADuser -Filter "Description -eq $($user.id)").DistinguishedName
}

# Add any changes to the splat
ForEach($property in $expectedProperties.GetEnumerator()){
    If($adUser.$($property.name) -ne $user.$($property.value)){
        $splat[$($property.Name)] = $user.$($property.value)
    }
}

# Account for any special properties
$managerFromHR = Get-ADUser $user.manager.Replace(' ','.')
If($managerFromHR.DistinguishedName -ne $adUser.Manager){
    $splat['Manager'] = $managerFromHR.DistinguishedName
}

# Naming steps
If($splat.Contains('GivenName') -or $splat.Contains('SurName')){
    $renameSplat = @{
        Identity = $adUser.DistinguishedName
        NewName = "$($user.first_name) $($user.last_name)"
    }
    Rename-ADObject @renameSplat
    $splat['SamAccountName'] = "$($user.first_name).$($user.last_name)"
}

# Apply the changes
Set-ADUser @splat

# Verify
Get-ADUser -Filter "Description -eq $($user.id)" -Properties Title

#endregion

#region Before we make it a function
# _gte parameter, API specific
Invoke-RestMethod "$baseUri/$resource`?lastmodified_gte=2019.01.28"

#endregion

#region Functionize it!
Function Update-ADUsersFromHR {
    [cmdletbinding()]
    Param (
        [Parameter(
            Mandatory = $true
        )]
        [datetime]$LastModified
    )
    # Properties HT
    $expectedProperties = @{
        Name = 'full_name'
        GivenName = 'first_name'
        SurName = 'last_name'
        Title = 'job_title'
        OfficePhone = 'phone'
    }
    # API uris
    $baseuri = 'http://techsnips_hr.io'
    $resource = 'employees'
    # Make the call
    $uri = "$baseUri/$resource`?lastmodified_gte=$(Get-Date $LastModified -Format yyyy.MM.dd)"
    Write-Verbose $uri
    $updates = Invoke-RestMethod -Uri $uri
    # Deal with the data
    ForEach($user in $updates){
        $adUser = Get-ADuser -Filter "Description -eq $($user.id)" -Properties *
        Write-Verbose "Found user: $($aduser.Name)"
        # Build a splat
        $splat = @{
            Identity = $adUser.DistinguishedName
        }
        # Add any changes to the splat
        ForEach($property in $expectedProperties.GetEnumerator()){
            If($adUser.$($property.name) -ne $user.$($property.value)){
                $splat[$($property.Name)] = $user.$($property.value)
                Write-Verbose " - Property $($property.Name) will be updated to: $($user.$($property.value))"
            }
        }
        # Account for any special properties
        If($user.manager){
            $managerFromHR = Get-ADUser $user.manager.Replace(' ','.')
            If($managerFromHR.DistinguishedName -ne $adUser.Manager){
                $splat['Manager'] = $managerFromHR.DistinguishedName
                Write-Verbose " - Manager will be updated to: $($managerFromHR.DistinguishedName)"
            }
        }
        # Naming steps
        If($splat.Contains('GivenName') -or $splat.Contains('SurName')){
            $renameSplat = @{
                Identity = $adUser.DistinguishedName
                NewName = "$($user.first_name) $($user.last_name)"
            }
            Write-Verbose " - Renaming to $($user.first_name) $($user.last_name)"
            Rename-ADObject @renameSplat
            Write-Verbose " - Setting SamAccountName to: $($user.first_name).$($user.last_name)"
            $splat['SamAccountName'] = "$($user.first_name).$($user.last_name)"
        }
        # Apply the changes
        If($splat.Count -gt 1){
            Set-ADUser @splat
            Write-Verbose " - Changes applied."
        }Else{
            Write-Verbose "No changes found"
        }
    }
}

# Usage
Update-ADUsersFromHR -LastModified (Get-Date).AddDays(-2) -Verbose

#endregion