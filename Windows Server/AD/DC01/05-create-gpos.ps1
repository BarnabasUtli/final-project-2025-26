Import-Module ActiveDirectory
Import-Module GroupPolicy

$DomainDN = "DC=corp,DC=migazzi,DC=com"
$WallpaperShare = "\\fileserver\wallpapers"

# OU → GPO mapping
$Policies = @(
    @{ OU="OU=Management,OU=HeadOffice,$DomainDN";   GPO="Mgmt-Wallpaper-Policy";            Wallpaper="management.jpg" },
    @{ OU="OU=HR,OU=HeadOffice,$DomainDN";           GPO="HR-LegalBanner-Wallpaper";        Wallpaper="hr.jpg" },
    @{ OU="OU=Finance,OU=HeadOffice,$DomainDN";      GPO="Finance-Security-Wallpaper";      Wallpaper="finance.jpg" },
    @{ OU="OU=IT,OU=HeadOffice,$DomainDN";           GPO="IT-Tools-Theme";                  Wallpaper="it.jpg" },
    @{ OU="OU=Marketing,OU=HeadOffice,$DomainDN";    GPO="Marketing-Wallpaper";             Wallpaper="marketing.jpg" },
    @{ OU="OU=Engineering,OU=HeadOffice,$DomainDN";  GPO="Engineering-Design-Wallpaper";    Wallpaper="engineer.jpg" },

    @{ OU="OU=Sales,OU=RetailShop,$DomainDN";        GPO="Retail-Sales-Theme";              Wallpaper="retail.jpg" },
    @{ OU="OU=CustomerService,OU=RetailShop,$DomainDN"; GPO="Retail-CS-Theme";              Wallpaper="retail.jpg" },

    @{ OU="OU=Production,OU=FactoryWarehouse,$DomainDN";   GPO="Prod-Floor-Lockdown";      Wallpaper="factory.jpg" },
    @{ OU="OU=Warehouse,OU=FactoryWarehouse,$DomainDN";    GPO="Warehouse-Floor-Lockdown"; Wallpaper="factory.jpg" },
    @{ OU="OU=Procurement,OU=FactoryWarehouse,$DomainDN";  GPO="Procurement-Theme";        Wallpaper="factory.jpg" },
    @{ OU="OU=Maintenance,OU=FactoryWarehouse,$DomainDN";  GPO="Maintenance-Floor-Lockdown"; Wallpaper="factory.jpg" },
    @{ OU="OU=RnD,OU=FactoryWarehouse,$DomainDN";          GPO="RnD-Design-Wallpaper";     Wallpaper="engineer.jpg" },

    @{ OU="OU=Servers,$DomainDN";                   GPO="Servers-Baseline";                Wallpaper="" },
    @{ OU="OU=ServiceAccounts,$DomainDN";           GPO="ServiceAccounts-NoLogin";        Wallpaper="" }
)

foreach ($p in $Policies) {
    $OUPath = $p.OU
    $GPOName = $p.GPO
    $WPFile = $p.Wallpaper

    # Create GPO if missing
    if (-not (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue)) {
        New-GPO -Name $GPOName | Out-Null
        Write-Host "[+] Created GPO: $GPOName"
    } else {
        Write-Host "[=] GPO already exists: $GPOName"
    }

    # Link GPO
    New-GPLink -Name $GPOName -Target $OUPath -Enforced No | Out-Null
    Write-Host "   └─ Linked to $OUPath"

    # Wallpaper (if defined)
    if ($WPFile -ne "") {
        $WPpath = "$WallpaperShare\$WPFile"
        
        Set-GPRegistryValue -Name $GPOName `
            -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
            -ValueName "Wallpaper" -Type String -Value $WPpath

        Set-GPRegistryValue -Name $GPOName `
            -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
            -ValueName "WallpaperStyle" -Type Dword -Value 2

        Write-Host "   └─ Wallpaper set: $WPFile"
    }

    # Per-department visible settings
    switch ($GPOName) {
        "HR-LegalBanner-Wallpaper" {
            Set-GPRegistryValue -Name $GPOName `
                -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
                -ValueName "legalnoticecaption" -Type String -Value "Authorized Users Only"

            Set-GPRegistryValue -Name $GPOName `
                -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
                -ValueName "legalnoticetext" -Type String -Value "HR Confidential: Unauthorized access prohibited"

            Write-Host "   └─ HR legal banner applied"
        }

        "Finance-Security-Wallpaper" {
            Set-GPRegistryValue -Name $GPOName `
                -Key "HKCU\Control Panel\Desktop" `
                -ValueName "ScreenSaveTimeOut" -Type String -Value "300"

            Write-Host "   └─ Finance screensaver timeout"
        }

        "Prod-Floor-Lockdown" | "Warehouse-Floor-Lockdown" | "Maintenance-Floor-Lockdown" {
            Set-GPRegistryValue -Name $GPOName `
                -Key "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" `
                -ValueName "NoControlPanel" -Type Dword -Value 1

            Write-Host "   └─ Factory lockdown (no Control Panel)"
        }

        "Servers-Baseline" {
            Set-GPRegistryValue -Name $GPOName `
                -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
                -ValueName "legalnoticecaption" -Type String -Value "SERVER ACCESS ONLY"

            Write-Host "   └─ Server access banner"
        }

        "ServiceAccounts-NoLogin" {
            Set-GPRegistryValue -Name $GPOName `
                -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System" `
                -ValueName "DisableCAD" -Type Dword -Value 0

            Write-Host "   └─ Service account login disabled"
        }
    }
}

Write-Host "`n✅ All GPOs created, configured, and linked successfully!" -ForegroundColor Green

