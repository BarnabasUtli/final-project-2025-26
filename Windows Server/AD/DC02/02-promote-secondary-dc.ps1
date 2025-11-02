<#
promote-secondary-dc.ps1
Purpose: Install AD DS role and promote this server as an additional Domain Controller in an existing domain.
Run as Administrator on the prepared target server (after reboot and domain join).
This script will:
 - Install AD-Domain-Services feature
 - Promote server to Domain Controller using Install-ADDSDomainController
 - Configure DNS role during promotion
Important: You will be prompted for Domain Admin credentials and a DSRM password. The server will reboot during promotion.
#>

# -------------------------
# CONFIGURE THESE VALUES
# -------------------------
$DomainName = "corp.migazzi.com"       # Your existing AD domain FQDN
$SiteName   = "Default-First-Site-Name" # Optional: AD site name for this DC
# Optional: specify a specific existing DC to replicate from (FQDN). If empty, AD will choose.
$ReplicationSourceDC = ""              # e.g. "dc01.corp.migazzi.com". Leave empty to let AD choose.

# Optional: paths for DB/Logs/SYSVOL (adjust if you want custom locations)
$DatabasePath = "C:\Windows\NTDS"
$LogPath      = "C:\Windows\NTDS"
$SysvolPath   = "C:\Windows\SYSVOL"

# -------------------------
# BEGIN
# -------------------------
Write-Host "=== PROMOTE: Starting AD DS install & DC promotion ===" -ForegroundColor Cyan

# Check if the server is already a Domain Controller
try {
    $isDC = (Get-ADDomainController -Identity $env:COMPUTERNAME -ErrorAction Stop) -ne $null
    if ($isDC) {
        Write-Host "This server is already a Domain Controller. Exiting." -ForegroundColor Yellow
        exit 0
    }
} catch {
    # Not a DC (expected)
    Write-Host "Server is not currently a DC. Proceeding..." -ForegroundColor Green
}

# Import modules
Import-Module ServerManager -ErrorAction SilentlyContinue
Import-Module ADDSDeployment -ErrorAction Stop

# Install AD DS role (and tools)
Write-Host "Installing AD DS role and management tools..." -ForegroundColor Yellow
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -Verbose

# Get Domain Admin credentials
$cred = Get-Credential -Message "Enter Domain Admin credentials (DOMAIN\user) for promotion"

# DSRM (local restore) password for the new DC
$SafeModePassword = Read-Host "Enter SafeMode (DSRM) password for this DC" -AsSecureString

# If replication source specified, validate it
if ($ReplicationSourceDC -ne "") {
    Write-Host "Replication source DC specified: $ReplicationSourceDC" -ForegroundColor Yellow
}

# Build parameters for Install-ADDSDomainController
$installParams = @{
    Credential = $cred
    DomainName = $DomainName
    InstallDns = $true
    SafeModeAdministratorPassword = $SafeModePassword
    DatabasePath = $DatabasePath
    LogPath = $LogPath
    SysvolPath = $SysvolPath
    NoGlobalCatalog = $false
    Force = $true
}

if ($SiteName -and $SiteName -ne "") {
    $installParams['SiteName'] = $SiteName
}

if ($ReplicationSourceDC -ne "") {
    $installParams['ReplicationSourceDC'] = $ReplicationSourceDC
}

# Kick off promotion (this will trigger a reboot)
Write-Host "Starting domain controller promotion. This operation will restart the server when finished." -ForegroundColor Magenta
Install-ADDSDomainController @installParams

# Note: Install-ADDSDomainController will not return on success (it reboots). After reboot check status.

