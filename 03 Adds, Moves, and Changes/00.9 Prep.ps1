$adfine = @{
    Name = 'Main'
    Precedence = 1
    ComplexityEnable = $true
    LockoutDuration = New-TimeSpan -Days 1
    LockoutThreshold = 5
}
New-ADFineGrainedPasswordPolicy @adfine
# To be able to lock him out from a DC
Add-ADGroupMember 'Domain Admins' -Members 'Jesse Pinkman'
$jesseCred = [pscredential]::new('techsnipsdemo\jesse.pinkman',(ConvertTo-SecureString 'SomeRandomPass1!' -AsPlainText -Force))
For($x=0;$x -le 5;$x++){
    Enter-PSSession DC01 -Credential $jesseCred
}