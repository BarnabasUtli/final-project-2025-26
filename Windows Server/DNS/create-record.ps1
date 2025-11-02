# ----------------------------
# CONFIG
# ----------------------------
$ZoneName = "corp.migazzi.com"   # DNS zóna neve (AD integrált)
$RecordName = "migazzi.com"      # A rekord neve (ez lehet @ vagy üres a root-hoz)
$IPAddress = "192.168.20.9"      # Webszerver IP címe
$TTL = 3600                      # 1 óra TTL

# ----------------------------
# SCRIPT
# ----------------------------
Import-Module DNSServer

# Ellenőrzés, hogy a rekord már létezik-e
$existing = Get-DnsServerResourceRecord -ZoneName $ZoneName -Name $RecordName -ErrorAction SilentlyContinue

if ($existing) {
    Write-Host "[-] A rekord már létezik: $RecordName -> $($existing.RecordData.IPv4Address)"
} else {
    # Hozzáadás
    Add-DnsServerResourceRecordA -Name $RecordName -ZoneName $ZoneName -IPv4Address $IPAddress -TimeToLive ([TimeSpan]::FromSeconds($TTL))
    Write-Host "[+] A rekord létrehozva: $RecordName -> $IPAddress"
}

