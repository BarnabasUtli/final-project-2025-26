Import-Module ActiveDirectory

$CSV = Import-Csv -Path "..\users.csv"

foreach ($user in $CSV) {
    $First = $user.FirstName
    $Last = $user.LastName
    $UPN = "$First.$Last@corp.migazzi.com"
    $Sam = "$First.$Last".ToLower()
    $OU = $user.OU

    New-ADUser `
        -GivenName $First `
        -Surname $Last `
        -SamAccountName $Sam `
        -UserPrincipalName $UPN `
        -Name "$First $Last" `
        -DisplayName "$First $Last" `
        -AccountPassword (ConvertTo-SecureString "DefaultPass123!" -AsPlainText -Force) `
        -Enabled $true `
        -ChangePasswordAtLogon $true `
        -Path $OU

    Write-Host "Created AD user: $First $Last ($Sam)"
}

