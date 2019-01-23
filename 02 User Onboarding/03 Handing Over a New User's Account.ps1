#region Enabling the account
Set-ADUser 'Walter White' -Enabled $true

# Generate a random password
# [system.web.security.membership]::GeneratePassword(a,b) a = length, b = minimum non-alphanumeric characters
# May need to: Add-Type -AssemblyName System.Web
$randomPassword = [System.Web.Security.Membership]::GeneratePassword(10,1)

# Set the new account with this info
Set-ADAccountPassword -Identity 'Walter White' -NewPassword (ConvertTo-SecureString $randomPassword -AsPlainText -Force) -Reset

# Enable the account
Set-ADUser 'Walter White' -Enabled $true -ChangePasswordAtLogon $true

# Verify
Get-ADUser 'Walter White'

#endregion

#region Notifying via email
# Sending an email from PowerShell
$exampleParams = @{
    Subject = 'Email subject line'
    Body = '<h1>Body</h1><p>this is the paragraph</p>'
    BodyAsHtml = $true
    To = 'email@domain.com'
    From =  'email@domain.coum'
    SmtpServer = 'smtp.domain.com'
    UseSSL = $true
}
Send-MailMessage @params

# Build an HTML template
$header = @"
<style>
table, th, td {
    border: 1px solid black;
  }
</style>
"@

$htmlTemplate = @"
<h1>Hello {0},</h1>
<p>HR says that you have a new minion starting:</p>
<table>
    <tr>
        <th>Name</th>
        <th>Logon Name</th>
        <th>Password</th>
    </tr>
    <tr>
        <th>{1}</th>
        <th>{2}</th>
        <th>{3}</th>
    </tr>
</table>
<p>Thanks!</p>
<p>Your friendly, neighborhood PowerShell automation system.</p>
"@

$html = $header + ($htmlTemplate -f 'Anthony','Walter White','Walter.White',"$randomPassword")
$params['body'] = $html
Send-MailMessage @params

#endregion

#region Email when creating users from a spreadsheet
Function Import-ADUsersFromSpreadsheet {
    [cmdletbinding(
        DefaultParameterSetName = 'Plain'
    )]
    Param(
        [ValidatePattern('.*\.xlsx$')]
        [ValidateNotNullOrEmpty()]
        [Parameter(
            ParameterSetName = 'FromTemplate'
        )]
        [Parameter(
            ParameterSetName = 'Plain'
        )]
        [string]$PathToSpreadsheet,
        [Parameter(
            ParameterSetName = 'FromTemplate',
            Mandatory = $true
        )]
        [Microsoft.ActiveDirectory.Management.ADUser]$TemplateUser,
        [Parameter(
            ParameterSetName = 'FromTemplate'
        )]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties = @('StreetAddress','City','State','PostalCode'),
        [Parameter(
            ParameterSetName = 'FromTemplate'
        )]
        [Parameter(
            ParameterSetName = 'Plain'
        )]
        [pscredential]$EmailCredential
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
            If($PSCmdlet.ParameterSetName -eq 'Plain'){
                New-ADUser @params
            }ElseIf($PSCmdlet.ParameterSetName -eq 'FromTemplate'){
                $props = $Properties + 'MemberOf'
                $template = Get-ADUser $TemplateUser -Properties $props
                New-ADUser @params -Instance $template
                ForEach($group in $template.MemberOf){
                    Add-ADGroupMember $group -Members $params['samaccountname']
                }
            }
            # Set the password
            $randomPassword = [System.Web.Security.Membership]::GeneratePassword(10,1)
            Set-ADAccountPassword -Identity $params['SamAccountName'] -NewPassword (ConvertTo-SecureString $randomPassword -AsPlainText -Force) -Reset

            # Enable the account
            Set-ADUser $params['SamAccountName'] -Enabled $true -ChangePasswordAtLogon $true

            # Email template
            $header = @"
<style>
table, th, td {
    border: 1px solid black;
  }
</style>
"@

            $htmlTemplate = @"
<h1>Hello {0},</h1>
<p>HR says that you have a new minion starting:</p>
<table>
    <tr>
        <th>Name</th>
        <th>Logon Name</th>
        <th>Password</th>
    </tr>
    <tr>
        <th>{1}</th>
        <th>{2}</th>
        <th>{3}</th>
    </tr>
</table>
<p>Thanks!</p>
<p>Your friendly, neighborhood PowerShell automation system.</p>
"@
            $html = $header + ($htmlTemplate -f $user.manager,$params['Name'],$params['SamAccountName'],"$randomPassword")
            # Email the manager
            $EmailParams = @{
                To = (Get-ADUser $params['Manager'] -Properties EmailAddress).EmailAddress
                From = $from
                Subject = 'You have a new minion!'
                Body = $html
                BodyAsHtml = $true
                UseSSL = $true
                SmtpServer = 'smtp.office365.com'
                Credential = $EmailCredential
            }
            Send-MailMessage @EmailParams
        }
    }
}

# Usage
Import-ADUsersFromSpreadsheet -PathToSpreadsheet '.\UserUpdate.xlsx' -EmailCredential $cred

# Verify
$SpreadSheet = '.\UserUpdate.xlsx'
$data = Import-Excel $SpreadSheet
ForEach($user in $data){
    Get-ADUser "$($user.'First Name').$($user.'Last Name')" -Properties StreetAddress | Select-Object Name,StreetAddress
}

#endregion