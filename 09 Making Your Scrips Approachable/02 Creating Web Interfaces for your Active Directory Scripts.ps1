#region Original function
Function Reset-ADUserPassword {
    [cmdletbinding(
        DefaultParameterSetName = 'Random'
    )]
    Param (
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Plain',
            Position = 1
        )]
        [Parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ParameterSetName = 'Random',
            Position = 1
        )]
        [Microsoft.ActiveDirectory.Management.ADUser]$Identity,
        [Parameter(
            ParameterSetName = 'Plain',
            Mandatory = $true
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Password
    )
    Begin{
        If($PSCmdlet.ParameterSetName -eq 'Plain'){
            # If $Password is specified, convert it to a secure string
            $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        }ElseIf($PSCmdlet.ParameterSetName -eq 'Random'){
            # Otherwise add this type to use the GeneratePassword method
            Add-Type -AssemblyName System.Web
        }
    }
    Process{
        If($PSCmdlet.ParameterSetName -eq 'Random'){
            # Generate a new random password for each user
            $securePassword = ConvertTo-SecureString ([System.Web.Security.Membership]::GeneratePassword(10,1)) -AsPlainText -Force
        }
        # Set the password
        Set-ADAccountPassword $Identity -NewPassword $securePassword -Reset
        # Force a password change
        Set-ADUser $Identity -ChangePasswordAtLogon $true
        # Output the user's name and result
        [pscustomobject]@{
            User = $Identity
            Password = [PScredential]::new("user",$SecurePassword).GetNetworkCredential().Password
        }
    }
    End{}
}
#endregion

#region WebJEAized
[cmdletbinding(
    DefaultParameterSetName = 'Random'
)]
Param (
    [Parameter(
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName = 'Plain',
        Position = 1
    )]
    [Parameter(
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName = 'Random',
        Position = 1
    )]
    [Microsoft.ActiveDirectory.Management.ADUser]$Identity,
    [Parameter(
        ParameterSetName = 'Plain'
    )]
    [ValidateNotNullOrEmpty()]
    [string]$Password
)
Begin{
    If($PSCmdlet.ParameterSetName -eq 'Plain'){
        # If $Password is specified, convert it to a secure string
        $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    }ElseIf($PSCmdlet.ParameterSetName -eq 'Random'){
        # Otherwise add this type to use the GeneratePassword method
        Add-Type -AssemblyName System.Web
    }
}
Process{
    If($PSCmdlet.ParameterSetName -eq 'Random'){
        # Generate a new random password for each user
        $securePassword = ConvertTo-SecureString ([System.Web.Security.Membership]::GeneratePassword(10,1)) -AsPlainText -Force
    }
    # Set the password
    Set-ADAccountPassword $Identity -NewPassword $securePassword -Reset
    # Force a password change
    Set-ADUser $Identity -ChangePasswordAtLogon $true
    # Output the user's name and result
    [pscustomobject]@{
        User = $Identity
        Password = [PScredential]::new("user",$SecurePassword).GetNetworkCredential().Password
    }
}
End{}
#endregion

#region prereqs
# onload_ADimport.ps1
Import-ActiveDirectory
#endregion

#region WebJEAized with help

<#
.SYNOPSIS
This function will reset a user's password

.DESCRIPTION
This function will reset the selected user's password with either the desired password or a randomly generated one.

.EXAMPLE
Reset-ADUserPassword.ps1 -User 'anthony.howell' -Password 'SomeRandomPasswordThatIsHardToGuess!'

Reset the password of anthony.howell to 'SomeRandomPasswordThatIsHardToGuess!'

.PARAMETER Identity
The user that you would like to target. It can be any identifying field of the user.

.PARAMETER Password
The password to set on the user account. If blank, it will be randomly generated.

.INPUTS

.OUTPUTS

.LINK

.NOTES

#>
[cmdletbinding(
    DefaultParameterSetName = 'Random'
)]
Param (
    [Parameter(
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName = 'Plain',
        Position = 1,
        HelpMessage = 'What user do you want to target?'
    )]
    [Parameter(
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName = 'Random',
        Position = 1
    )]
    [Microsoft.ActiveDirectory.Management.ADUser]$Identity,
    [Parameter(
        ParameterSetName = 'Plain',
        HelpMessage = 'What password should the user have?'
    )]
    [ValidateNotNullOrEmpty()]
    [string]$Password
)
Begin{
    If($PSCmdlet.ParameterSetName -eq 'Plain'){
        # If $Password is specified, convert it to a secure string
        $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    }ElseIf($PSCmdlet.ParameterSetName -eq 'Random'){
        # Otherwise add this type to use the GeneratePassword method
        Add-Type -AssemblyName System.Web
    }
}
Process{
    If($PSCmdlet.ParameterSetName -eq 'Random'){
        # Generate a new random password for each user
        $securePassword = ConvertTo-SecureString ([System.Web.Security.Membership]::GeneratePassword(10,1)) -AsPlainText -Force
    }
    # Set the password
    Set-ADAccountPassword $Identity -NewPassword $securePassword -Reset
    # Force a password change
    Set-ADUser $Identity -ChangePasswordAtLogon $true
    # Output the user's name and result
    [pscustomobject]@{
        User = $Identity
        Password = [PScredential]::new("user",$SecurePassword).GetNetworkCredential().Password
    }
}
End{}
#endregion

#region No Parameters example
<#
.SYNOPSIS
Returns unused GPOs from Active Directory
#>
[cmdletbinding()]
Param()
Function Get-ADOUStatus {
    param (
        [string]$Filter = '*'
    )
    ForEach($OU in Get-ADOrganizationalUnit -Filter $Filter){
        $objects = $null
        $objects = Get-ADObject -Filter {ObjectClass -ne 'OrganizationalUnit'} -SearchBase $OU
        If($objects){
            [pscustomobject]@{
                OU = $OU
                Empty = $false
                LinkedGPOs = [bool]$OU.LinkedGroupPolicyObjects
            }
        }Else{
            [pscustomobject]@{
                OU = $OU
                Empty = $true
                LinkedGPOs = [bool]$OU.LinkedGroupPolicyObjects
            }
        }
    }
}
$OUs = Get-ADOUStatus | Where-Object {$_.LinkedGPOs}
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
        ForEach($GPOGuid in $OU.LinkedGroupPolicyObjects){
            If($GPOGuid.Substring(4,36) -eq $GPO.GPOId){
                Write-Verbose "GPO: '$($GPO.GPOName)' also linked to non-empty OU: $($OU.Name)"
                If($GPO.NonEmptyOU){
                    $GPO.NonEmptyOU = [string[]]$GPO.NonEmptyOU + $OU.DistinguishedName
                }Else{
                    $GPO.NonEmptyOU = $OU.DistinguishedName
                }
            }
        }
    }
}
$GPOsLinkedToEmptyOUs

#endregion