#region
# Finding accounts soon to expire
$users = Search-ADACcount -AccountExpiring -TimeSpan '14.00:00:00'

# Find their manager
ForEach($user in $users){
    $manager = (Get-ADUser $user.SamAccountName -Properties Manager).Manager
    Get-ADUser $manager
}
#endregion

#region Notify
# Sending an email
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

# Format the users
$tableInfo = ''
ForEach($user in $users){
    $ts = New-TimeSpan -Start (Get-Date) -End $user.AccountExpirationDate
    [string]$tableInfo += "<tr><th>$($user.Name)</th><th>$($ts.Days)</th></tr>"
}

# Put them in HTML
$header = @"
<style>
table, th, td {
    border: 1px solid black;
  }
</style>
"@

$htmlTemplate = @"
<h1>Hello {0},</h1>
<p>You have minions with accounts that expire soon.</p>
<table>
    <tr>
        <th>Name</th>
        <th>Days till expiration</th>
    </tr>
    {1}
</table>
<p>Thanks!</p>
<p>Your friendly, neighborhood PowerShell automation system.</p>
"@

$html = $header + ($htmlTemplate -f $manager.GivenName,$tableInfo)
$params['body'] = $html
Send-MailMessage @params

#endregion

#region Don't forget to functionize it!
Function Send-ADAccountExpirations {
    param (
        [int]$DaysTillExpiration,
        [pscredential]$EmailCredential = $cred,
        [string]$From
    )
    $header = @"
<style>
table, th, td {
    border: 1px solid black;
    }
</style>
"@
    $htmlTemplate = @"
<h1>Hello {0},</h1>
<p>You have minions with accounts that expire soon.</p>
<table>
    <tr>
        <th>Name</th>
        <th>Days till expiration</th>
    </tr>
    {1}
</table>
<p>Thanks!</p>
<p>Your friendly, neighborhood PowerShell automation system.</p>
"@
    $users = @()
    $ts = New-TimeSpan -Start (Get-Date) -End (Get-Date).AddDays($DaysTillExpiration)
    $searchUsers = Search-ADACcount -AccountExpiring -TimeSpan $ts
    ForEach($user in $searchUsers){
        $users += Get-ADUser $user.SamAccountName -Properties Manager,AccountExpirationDate
    }
    $groupedUsers = $users | Group-Object Manager
    ForEach($group in $groupedUsers){
        $tableInfo = $null
        ForEach($user in $group.Group){
            $ts = New-TimeSpan -Start (Get-Date) -End $user.AccountExpirationDate
            [string]$tableInfo += "<tr><th>$($user.Name)</th><th>$($ts.Days)</th></tr>"
        }
        $manager = Get-ADUser $user.Manager -Properties EmailAddress
        $html = $header + ($htmlTemplate -f $manager.GivenName,$tableInfo)
        $EmailParams = @{
            To = $manager.EmailAddress
            From = $from
            Subject = 'Account Expiration Notification'
            Body = $html
            BodyAsHtml = $true
            UseSSL = $true
            SmtpServer = 'smtp.office365.com'
            Credential = $EmailCredential
        }
        Send-MailMessage @EmailParams
    }
}

# Usage
Send-ADAccountExpirations -DaysTillExpiration 14 -From $from

#endregion