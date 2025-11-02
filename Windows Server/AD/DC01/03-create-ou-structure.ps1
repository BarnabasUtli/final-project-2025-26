<#
Creates OU structure in Active Directory from CSV input file.
CSV format:
ParentOU,OUName
OU=SomeOU,DC=domain,DC=com,SubOU
#>

Import-Module ActiveDirectory

$csvPath = "..\ou-structure.csv"
$ouList = Import-Csv $csvPath

foreach ($entry in $ouList) {
    $parentPath = $entry.ParentOU
    $ouName = $entry.OUName

    $ouPath = "OU=$ouName,$parentPath"

    if (-not (Get-ADOrganizationalUnit -LDAPFilter "(ou=$ouName)" -SearchBase $parentPath -ErrorAction SilentlyContinue)) {
        try {
            New-ADOrganizationalUnit -Name $ouName -Path $parentPath -ProtectedFromAccidentalDeletion $true -ErrorAction Stop
            Write-Host "[+] Created OU: $ouPath" -ForegroundColor Green
        }
        catch {
            Write-Host "[!] Failed to create OU: $ouPath - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    else {
        Write-Host "[-] OU already exists: $ouPath" -ForegroundColor Yellow
    }
}
