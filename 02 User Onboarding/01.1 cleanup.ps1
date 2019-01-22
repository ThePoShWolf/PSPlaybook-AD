ForEach($user in $data){
    Remove-ADUser "$($user.'First Name').$($user.'Last Name')" -Confirm:$false
}