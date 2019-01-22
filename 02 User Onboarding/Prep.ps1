Import-Module ImportExcel
Copy-Item '.\02 User Onboarding\ADData.xlsx' -Destination C:\Temp\ -ToSession $sessions[0]
$data = Import-Excel