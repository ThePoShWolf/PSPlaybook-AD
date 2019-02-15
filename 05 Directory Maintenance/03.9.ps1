# Backup phone numbers
Get-ADUser -Filter {OfficePhone -like '*'} -Properties officephone | Select SamAccountName,OFficePhone | Export-Csv .\phones.csv -NoTypeInformation

# Restore
Import-CSV .\phones.csv | %{Set-ADUser $_.SamAccountName -OfficePhone $_.officephone}