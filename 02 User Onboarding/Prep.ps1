$PSDefaultParameterValues = @{
    '*-AD*:Server' = 'DC01'
    '*-AD*:Credential' = $cred
}

Import-Module ImportExcel
Copy-Item '.\02 User Onboarding\ADData.xlsx' -Destination C:\Temp\ -ToSession $sessions[0]
$data = Import-Excel '.\02 User Onboarding\ADData.xlsx'

ForEach($user in $data){
    New-ADUser -Name "$($user.GivenName) $($user.SurName)" `
        -UserPrincipalName "$($user.GivenName).$($user.SurName)@techsnipsdemo.local" `
        -GivenName $user.GivenName `
        -Surname $user.SurName `
        -OfficePhone $user.PhoneNumber `
        -Department $user.Department `
        -Title $user.Title `
        -State $user.State -Verbose
}
(get-aduser -Filter * -Properties department).department | select -unique | %{New-ADGroup -GroupCategory Security -GroupScope Global -Name "$_ Department"}
get-aduser -Filter * -Properties department | %{Add-ADGroupMember "$($_.department) Department" -Members $_}
(get-aduser -Filter * -Properties title).title | %{$_ -replace ' [IV]+$',''} | select -unique | %{New-ADGroup -GroupCategory Security -GroupScope Global -Name "$($_)s"}
get-aduser -Filter * -Properties title | %{$group = $_.title -replace ' [IV]+$','';Add-ADGroupMember -Identity "$($group)s" -Members $_}
New-ADGroup -GroupCategory Security -GroupScope Global -Name 'Managers'
get-aduser -Filter {Title -like '*manager*'} | %{Add-ADGroupMember -Identity Managers -Members $_}
New-ADGroup -GroupCategory Security -GroupScope Global -Name 'Executives'
get-aduser -Filter {Title -like '*Executive*'} | %{Add-ADGroupMember -Identity 'Executives' -Members $_}
New-ADGroup -GroupCategory Security -GroupScope Global -Name 'VPs'
get-aduser -Filter {Title -like '*VP*'} | %{Add-ADGroupMember -Identity 'VPs' -Members $_}
New-ADGroup -GroupCategory Security -GroupScope Global -Name 'Engineers'
get-aduser -Filter {Title -like '*Engineer*'} | %{Add-ADGroupMember -Identity 'Engineers' -Members $_}