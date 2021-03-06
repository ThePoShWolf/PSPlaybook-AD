$baseUri = 'http://techsnips_hr.io'
$resource = 'employees'

$SpreadSheet = '.\02 User Onboarding\UserUpdate.xlsx'
$SpreadSheet = '.\UserUpdate.xlsx'
$Data = Import-Excel $SpreadSheet

$header = @{
    'Content-Type'='application/json'
}

ForEach($user in $data){
    $json = @{
        full_name = $user.'Full Name'
        first_name = $user.'First Name'
        last_name = $user.'Last Name'
        department = $user.department
        job_title = $user.'Job Title'
        phone = $user.'Phone Number'
        manager = $user.manager
    } | ConvertTo-Json
    Invoke-RestMethod -Uri "$baseUri/$resource" -Method Post -Headers $header -Body $json
}

$current = Invoke-RestMethod -Uri $baseUri/$resource
ForEach($user in $current){
    Invoke-RestMethod -Uri $baseUri/$resource/$($user.id) -Method Delete
    Start-Sleep -Milliseconds 25
}

$users = Get-ADUser -Filter {department -like '*'} -Properties GivenName,Department,Title,OfficePhone,Manager
$date = Get-Date ((Get-Date).AddDays(-7)) -Format yyyy.MM.dd
ForEach($user in $users){
    $json = @{
        full_name = $user.Name
        first_name = $user.GivenName
        last_name = $user.SurName
        department = $user.department
        job_title = $user.Title
        phone = $user.OfficePhone
        manager = $user.Manager
        lastmodified = $date
    } | ConvertTo-Json
    Invoke-RestMethod -Uri $baseUri/$resource -Method Post -Headers $header -Body $json
    Start-Sleep -Milliseconds 25
}

$current = Invoke-RestMethod -Uri $baseUri/$resource
$date = get-date -Format yyyy.MM.dd
ForEach($user in $current){
    $json = @{
        lastmodified = $date
    } | Convertto-Json
    Invoke-RestMethod -Uri $baseUri/$resource/$($user.id) -Method Put -Headers $header -Body $json
    Start-Sleep -Milliseconds 25
}

Invoke-RestMethod -Uri "$baseUri/$resource`?lastmodified_gte=2019.01.19"

$json = @{
    lastmodified = Get-Date ((Get-Date).AddDays(-6)) -Format yyyy.MM.dd
} | ConvertTo-Json

$current = Invoke-RestMethod -Uri "$baseUri/$resource`?manager_like=C"
ForEach($user in $current){
    $json = @{
        manager = (Get-ADUser $user.manager).Name
    } | ConvertTo-Json
    Invoke-RestMethod -Uri "$baseUri/$resource/$($user.id)" -Method Patch -Headers $header -Body $json
}

$ids = 1..606 | Get-Random -Count 2
$rand
ForEach($id in $ids){
    Invoke-RestMethod -Uri "$baseUri/$resource/$id"
}

$ids = '349','258'

$user = Invoke-RestMethod -Uri "$baseUri/$resource/$($ids[0])"
$user.last_name = 'Fring' #'Hirtzmann'
$user.full_name = 'Halli Fring' #Hirtzmann'
$user.lastmodified = '2019.01.28'

$json = $user | ConvertTo-Json
Invoke-RestMethod -Uri "$baseUri/$resource/$($ids[0])" -Method Patch -Headers $header -Body $json

$user = Invoke-RestMethod -Uri "$baseUri/$resource/$($ids[1])"
$user.job_title = 'Human Resources Assistant II' # I
$user.lastmodified = '2019.01.28'

$json = $user | ConvertTo-Json
Invoke-RestMethod -Uri "$baseUri/$resource/$($ids[1])" -Method Patch -Headers $header -Body $json

$users = Invoke-RestMethod $baseuri/$resource -Method Get
ForEach($user in $users){
    Set-ADUser "$($user.first_name).$($user.last_name)" -Description $user.id
}