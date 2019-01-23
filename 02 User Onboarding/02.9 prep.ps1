$params = @{
    To = 'anthony@howell-it.com'
    From = 'anthony@howell-it.com'
    Credential = Get-Credential
    Subject = 'Email subject line'
    Body = '<h1>Body</h1><p>this is the paragraph</p>'
    BodyAsHtml = $true
    SmtpServer = 'smtp.office365.com'
    UseSSL = $true
}


foreach($user in $data){
    Set-ADUser $user.Manager.Replace(' ','.') -EmailAddress 'anthony@howell-it.com'
}
$global:From = 'anthony@howell-it.com'

$cred = Get-Credential