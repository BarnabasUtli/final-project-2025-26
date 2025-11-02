<#
.SYNOPSIS
Initial base configuration script for a new domain controller.
Sets hostname, static IP, gateway, DNS servers.

Run as Administrator BEFORE promoting to DC.
#>

############################
# ---- USER VARIABLES ---- #
############################

# Hostname to assign
$NewHostname = "DC01"

# Network adapter name (use Get-NetAdapter to confirm)
$Adapter = "Ethernet"

# IP Settings
$IPAddress   = "192.168.20.2"
$PrefixLen   = 24     # /24 subnet mask
$Gateway     = "192.168.20.1"
$DnsPrimary  = "192.168.20.2"    # AD DNS (self)

############################
# ---- BEGIN CONFIG ---- #
############################

Write-Host "Starting base configuration..." -ForegroundColor Cyan

# Rename Server
Write-Host "Renaming computer to $NewHostname ..." -ForegroundColor Yellow
Rename-Computer -NewName $NewHostname -Force

# Remove DHCP address
Write-Host "Clearing existing IP configuration..." -ForegroundColor Yellow
Get-NetIPAddress -InterfaceAlias $Adapter -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false

# Set Static IP
Write-Host "Configuring static IP: $IPAddress/$PrefixLen" -ForegroundColor Yellow
New-NetIPAddress -InterfaceAlias $Adapter -IPAddress $IPAddress -PrefixLength $PrefixLen -DefaultGateway $Gateway

# Set DNS
Write-Host "Setting DNS to $DnsPrimary (primary)" -ForegroundColor Yellow
Set-DnsClientServerAddress -InterfaceAlias $Adapter -ServerAddresses $DnsPrimary

Write-Host "Configuration applied. Restarting..." -ForegroundColor Green
Restart-Computer -Force

