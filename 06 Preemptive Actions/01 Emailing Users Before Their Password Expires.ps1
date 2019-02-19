#region Getting the password expiration date
# msDS-UserPasswordExpiryTimeComputed property
$userParams = @{
    Identity = 'Walter White'
    Properties = 'Name','msDS-UserPasswordExpiryTimeComputed'
}
Get-ADUser @userParams | Format-Table $userParams['Properties']

# Save to a variable
$user = Get-ADUser @userParams

# Try Get Date
Get-Date $user.'msDS-UserPasswordExpiryTimeComputed'

# .NET
[datetime]::FromFileTime($user.'msDS-UserPasswordExpiryTimeComputed')
$expirationDate = [datetime]::FromFileTime($user.'msDS-UserPasswordExpiryTimeComputed')

# Now how far away is that?
New-TimeSpan -Start (Get-Date) -End $expirationDate

# Assign time span to variable
$ts = New-TimeSpan -Start (Get-Date) -End $expirationDate

#endregion

#region Finding all users' with soon expiring passwords
# First we need a filter:
$filter = {Enabled -eq $true -and PasswordNeverExpires -eq $false}

# Get all those users
Get-ADUser -Filter $filter

# Then define what 'soon' is
$days = 44

# Convert that to filetime
$date = (Get-Date).AddDays($days).ToFileTime()

# And get all the users
Get-ADUser -Filter $filter -Properties 'msDS-UserPasswordExpiryTimeComputed' | `
Where-Object {$_.'msDS-UserPasswordExpiryTimeComputed' -lt $date}
#endregion

#region Now lets make that data useful!
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

# Create an email template
$htmlTemplate = @"
<h1>Hello {0},</h1>
<p>Your password expires soon. In fact, it expires in {1}.</p>
<p>Make sure you reset it before it becomes a problem <span>&#128522;</span></p>
<p>Thanks!</p>
<p>Your friendly, neighborhood PowerShell automation system.</p>
"@

$html = $htmlTemplate -f $User.GivenName, "$($ts.Days) days"
$params['Subject'] = 'Password expiration notification'
$params['Body'] = $html
Send-MailMessage @params
#endregion

#region The end... Or should we write a function first?
Function Send-ADPasswordReminders {
    [cmdletbinding()]
    param (
        [int]$DaysTillExpiration,
        [string]$From = 'anthony@howell-it.com',
        [pscredential]$EmailCredential = $cred
    )
    $htmlTemplate = @"
<h1>Hello {0},</h1>
<p>Your password expires soon. In fact, it expires in {1}.</p>
<p>Make sure you reset it before it becomes a problem <span>&#128522;</span></p>
<p>Thanks!</p>
<p>Your friendly, neighborhood PowerShell automation system.</p>
"@
    $adUserParams = @{
        Filter = {Enabled -eq $true -and PasswordNeverExpires -eq $false}
        Properties = 'msDS-UserPasswordExpiryTimeComputed','EmailAddress'
    }
    $expFileTime = (Get-Date).AddDays($DaysTillExpiration).ToFileTime()
    $users = Get-ADUser @adUserParams | Where-Object {$_.'msDS-UserPasswordExpiryTimeComputed' -lt $expFileTime}
    ForEach ($user in $users){
        $ts = New-TimeSpan -Start (Get-Date) -End ([datetime]::FromFileTime($user.'msDS-UserPasswordExpiryTimeComputed'))
        $html = $htmlTemplate -f $User.GivenName, "$($ts.Days) days"
        $EmailParams = @{
            To = $user.EmailAddress
            From = $from
            Subject = 'Password Expiration Notification'
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
Send-ADPasswordReminders -DaysTillExpiration 50

#endregion