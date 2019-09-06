# Create different email addresses
Get-ADUser -Filter * -Properties EmailAddress | Get-Random -Count 28 | %{
    Set-ADUser $_ -EmailAddress "$($_.GivenName[0])$($_.SurName)@techsnipsdemo.org" -UserPrincipalName "$($_.GivenName[0])$($_.SurName)@techsnipsdemo.local"
}

# Fix UPNs
Get-ADUser -Filter * | %{
    Set-ADUser $_ -UserPrincipalName "$($_.SamAccountName)@techsnipsdemo.local"
}

# create mail contacts
$users = Get-ADUser -Filter * -Properties OfficePhone,EmailAddress,Title | Get-Random -Count 17
$users | %{
    New-ADObject -Type Contact -Name $_.Name -DisplayName $_.Name -Description "Acme Inc - $($_.Title)" -OtherAttributes @{
        homePhone = $_.OfficePhone
        mail = $_.EmailAddress
    }
}