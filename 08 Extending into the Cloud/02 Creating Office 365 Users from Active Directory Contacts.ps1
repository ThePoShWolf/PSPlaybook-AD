#region
# Find all your AD Contacts
Get-ADObject -Filter {ObjectClass -eq 'Contact'}

# Get the relevant info to create a user in O365
$contacts = Get-ADObject -Filter {ObjectClass -eq 'Contact'} -Properties *

# AzureAD Module
# Install-Module AzureAD
Import-Module AzureAD
Connect-AzureAD -Credential $creds

# Create the password profile
# Add-Type -AssemblyName System.Web
$PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
$PasswordProfile.Password = [System.Web.Security.Membership]::GeneratePassword(10,1)

# Map local properties to their AAD equivalents
# localprop = aadProp
$props = @{
    DisplayName = 'DisplayName'
    GivenName = 'GivenName'
    sn = 'SurName'
    mail = 'UserPrincipalName'
}

# Check if the user exists already
Get-AzureADUser -ObjectId $contacts[0].mail

# Build the params hashtable
$aadUserParams = @{}
foreach ($prop in $props.keys) {
    if ($null -ne $contacts[0]."$prop") {
        $aadUserParams["$($props[$prop])"] = $contacts[0]."$prop"
    }
}
$aadUserParams['AccountEnabled'] = $false
$aadUserParams['PasswordProfile'] = $PasswordProfile
$aadUserParams['MailNickname'] = $contacts[0].mail.Split('@')[0]

# If the UserPrincipalName isn't null, create the user
if ($null -ne $aadUserParams['UserPrincipalName']) {
    New-AzureADUser @aadUserParams
}

# Verify
Get-AzureADUser -ObjectId $contacts[0].mail

#endregion

#region I think we'll pass on functionizing this one...
# just kidding
Function Copy-ADContactsToO365 {
    Param(
        [string]$SearchBase = 'OU=Contacts,DC=techsnipsdemo,DC=org'
    )
    # mapping hashtable
    $props = @{
        DisplayName = 'DisplayName'
        GivenName = 'GivenName'
        sn = 'SurName'
        mail = 'UserPrincipalName'
    }
    # get all the contacts
    $getadobjParams = @{
        Filter = "ObjectClass -eq 'Contact'"
        Properties = '*'
        SearchBase = $SearchBase
    }
    $contacts = Get-ADObject @getadobjParams
    foreach ($contact in $contacts) {
        $aadUserParams = @{}
        try{
            Get-AzureADUser -ObjectId $contact.mail
        } Catch [Microsoft.Open.AzureAD16.Client.ApiException] {
            # User likely doesn't exist
            foreach ($prop in $props.keys) {
                if ($null -ne $contact."$prop") {
                    $aadUserParams["$($props[$prop])"] = $contact."$prop"
                }
            }
            # Create the password profile
            $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
            $PasswordProfile.Password = [System.Web.Security.Membership]::GeneratePassword(10,1)

            # Set the known parameters
            $aadUserParams['AccountEnabled'] = $false
            $aadUserParams['PasswordProfile'] = $PasswordProfile
            $aadUserParams['MailNickname'] = $contact.mail.Split('@')[0]

            # If the UserPrincipalName isn't null, create the user
            if ($null -ne $aadUserParams['UserPrincipalName']) {
                New-AzureADUser @aadUserParams
            }
        }
    }
}

#Usage
Copy-ADContactsToO365

#endregion