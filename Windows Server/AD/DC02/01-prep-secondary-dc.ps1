<#
prep-secondary-dc.ps1
Purpose: Prepare a Windows server to become an additional Domain Controller.
Actions:
 - Set hostname
 - Configure static IPv4 and DNS (pointing to an existing DC)
 - Optionally join the domain (requires Domain Admin credentials)
Run as Administrator on the target server.
#>

# -------------------------
# CONFIGURE THESE VALUES
# -------------------------
$NewHostname   = "DC02"                        # Desired NetBIOS/hostname
$Adapter       = "Ethernet"                    # NIC name (Get-NetAdapter)
$IPAddress     = "192.168.20.3"                # Static IP for this server
$PrefixLength  = 24                            # e.g. 24 for /24
$Gateway       = "192.168.20.1"                # Gateway
$DnsServer     = "192.168.20.2"                # First entry should be an existing DC DNS
$DomainFQDN    = "corp.migazzi.com"            # Your AD domain
$DomainNetBIOS = "CORP"                        # Optional NetBIOS short name
$JoinDomain    = $true                         # Set $false if already joined
# -------------------------
# BEGIN
# -------------------------
Write-Host "=== PREP: Starting server prep for additional DC ===" -ForegroundColor Cyan

# 1) Rename computer if needed
$currentName = (Get-ComputerInfo -Property CsName).CsName
if ($currentName -ne $NewHostname) {
    Write-Host "Renaming computer from $currentName to $NewHostname..." -ForegroundColor Yellow
    Rename-Computer -NewName $NewHostname -Force -PassThru
    $renamePerformed = $true
} else {
    Write-Host "Hostname already set to $NewHostname"
    $renamePerformed = $false
}

# 2) Configure static IP
try {
    $adapter = Get-NetAdapter -Name $Adapter -ErrorAction Stop
} catch {
    Write-Error "Network adapter '$Adapter' not found. Run Get-NetAdapter and adjust \$Adapter variable."
    exit 1
}

# Remove existing IPv4 addresses on the adapter (safe attempt)
Get-NetIPAddress -InterfaceAlias $Adapter -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -ne $null } | ForEach-Object {
    Remove-NetIPAddress -InterfaceAlias $Adapter -IPAddress $_.IPAddress -Confirm:$false -ErrorAction SilentlyContinue
}

Write-Host "Configuring static IP $IPAddress/$PrefixLength and gateway $Gateway on $Adapter..." -ForegroundColor Yellow
New-NetIPAddress -InterfaceAlias $Adapter -IPAddress $IPAddress -PrefixLength $PrefixLength -DefaultGateway $Gateway -ErrorAction Stop

Write-Host "Setting DNS server to $DnsServer" -ForegroundColor Yellow
Set-DnsClientServerAddress -InterfaceAlias $Adapter -ServerAddresses $DnsServer

# Optional: disable IPv6 if desired (comment out if you want IPv6)
# Disable-NetAdapterBinding -Name $Adapter -ComponentID ms_tcpip6

# 3) Join domain if requested and not already joined
$domainJoinRequired = $JoinDomain -and -not ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain)
if ($domainJoinRequired) {
    Write-Host "Joining domain $DomainFQDN. Please provide Domain Admin credentials when prompted." -ForegroundColor Yellow
    $cred = Get-Credential -Message "Enter Domain Admin credentials to join $DomainFQDN (domain\user)"
    try {
        Add-Computer -DomainName $DomainFQDN -Credential $cred -Restart:$false -ErrorAction Stop
        Write-Host "Domain join requested. You may need to reboot to complete the join." -ForegroundColor Green
        $joinPerformed = $true
    } catch {
        Write-Error "Failed to join domain: $_"
        exit 1
    }
} else {
    Write-Host "Domain join not required or server already domain joined."
    $joinPerformed = $false
}

# 4) Reboot if we renamed the host or joined domain; else advise manual reboot
if ($renamePerformed -or $joinPerformed) {
    Write-Host "Rebooting server to apply hostname/domain changes..." -ForegroundColor Magenta
    Restart-Computer -Force
} else {
    Write-Host "Preparation complete. Reboot recommended before promoting to DC if not already done." -ForegroundColor Green
}

# End of prep script

