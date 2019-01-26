#region Retrieving data
# Source
$uri = 'http://techsnips_hr.io'
$resource = 'employees'

# Get data
Invoke-RestMethod $uri/$resource -Method Get

# Get a single employee
Invoke-RestMethod $uri/$resource/606 -Method Get

# Compare them to AD
$user = Invoke-RestMethod $uri/$resource/606 -Method Get
Get-ADUser "$($user.first_name).$($user.last_name)"

#endregion