<#
.SYNOPSIS
    A helper script to generate a client Wireguard profile.
.DESCRIPTION
    Requires Wireguard client to be installed. Get it from https://www.wireguard.com/install/
.PARAMETER $Name
    Profile file name
.PARAMETER $ClientIP
    Client IP assigned in your Wireguard network
.PARAMETER $DnsIP
    Optional DNS server IP to use. Note, it overrides your local DHCP provided DNS server
.PARAMETER $DnsZone
    Optional private DNS zone to resolve
.PARAMETER $AllowedIPs
    Specifies which IP addresses are allowed through this peer. Acts as a routing table and access control list
.PARAMETER $WgPublicKey
    Wireguard server public key
.PARAMETER $WgHost
    Wireguard server public IP or hostname
.PARAMETER $WgPort
    Wireguard server port. Defaults to 51820
.PARAMETER $KeepAlive
    Sends keepalive packets at the specified interval (in seconds) to maintain NAT mappings. Useful for peers behind NAT
.EXAMPLE
    chmod +x wg-profile.ps1
    pwsh .\wg-profile.ps1 -ClientIp 10.8.0.15 -AllowedIPs 10.8.0.1/24 -WgPublicKey "GzofaF5HJnmGFtX75bqYEIPLUqyNXrXMC1bFExlJfU4=" -WgHost wg.example.net
.EXAMPLE
    .\wg-profile.ps1 -ClientIp 10.8.0.15 -AllowedIPs 10.8.0.1/24 -WgPublicKey "GzofaF5HJnmGFtX75bqYEIPLUqyNXrXMC1bFExlJfU4=" -WgHost wg.example.net
.EXAMPLE
    .\wg-profile.ps1 -Name Alex -ClientIp 10.8.0.15 -AllowedIPs 10.8.0.1/24 -DnsIp 10.8.0.1 -DnsZone my-local -WgPublicKey "GzofaF5HJnmGFtX75bqYEIPLUqyNXrXMC1bFExlJfU4=" -WgHost wg.example.net -KeepAlive 25
.NOTES
This script does not directly update the password. It must be done manually following the steps above.
#>
param(
    [string]$Name,

    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)]
    [string]$ClientIP,

    [string]$DnsIP,

    [string]$DnsZone,

    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)]
    [string]$AllowedIPs,

    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)]
    [string]$WgPublicKey,

    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory=$true)]
    [string]$WgHost,

    [int]$WgPort = 51820,

    [int]$KeepAlive
)

Function Test-CommandExists
{
<#
.SYNOPSIS
    The function checks if a command exists and can be run.
.EXAMPLE
    Test-CommandExists wg.exe
#>
	Param ($command)
	$oldPreference = $ErrorActionPreference # we don't know the current setting, by default it's "continue"
	$ErrorActionPreference = "stop"

	try {
		if (Get-Command $command) { return $true }
	}
	catch {
		Write-Host "Command $command does not exist."; return $false;
	}
	finally {
		$ErrorActionPreference = $oldPreference # restore the prev value
	}
}

$WgCmd = "wg.exe"
if (-not (Test-CommandExists $WgCmd)) {
	$AllSet = $false
	Write-Warning "Make sure $WgCmd is available. Install the client from https://www.wireguard.com/install, if needed."
	Exit
}

if (!$Name) {
    $Name = (Get-Date).ToString("yyyMMddHHmmss")
}

# Generate private key and store in variable
$PrivateKey = & $WgCmd genkey
# Generate public key from private key, store in variable
$PublicKey = $privateKey | & $WgCmd pubkey

# Optional: output to console
"Private key: $PrivateKey"
"Public key:  $PublicKey"

$lines = @()
$lines += "[Interface]"
$lines += "PrivateKey = $PrivateKey"
$lines += "Address = $ClientIp/32"

if ($DnsIp -ne "") {
    $lines += "DNS = $DnsIp" + ($DnsZone -ne "" ? ", $DnsZone" : "")
}

$lines += ""
$lines += "[Peer]"
$lines += "PublicKey = $WgPublicKey"
$lines += "AllowedIPs = $AllowedIPs"
$lines += "Endpoint = $WgHost`:$WgPort"
if ($KeepAlive -gt 0) {
    $lines += "PersistentKeepalive = $KeepAlive"
}

$WgProfile = $lines -join [Environment]::NewLine
$WgProfileName = "$Name.conf"
"--------------------------------------------------------- $WgProfileName"
Write-Host $WgProfile -ForegroundColor green
"--------------------------------------------------------- $WgProfileName"

$WgProfile | Out-File -Encoding ascii $WgProfileName

$lines = @()
$lines += "# $Name"
$lines += "[Peer]"
$lines += "PublicKey = $PublicKey"
$lines += "AllowedIPs = $ClientIP/32"
$SrvWg = $lines -join [Environment]::NewLine

""
"Add this to your Wireguard server config at $WgHost. For example, in /etc/wireguard/wg0.conf:"
"---------------------------------------------------------"
Write-Host $SrvWg -ForegroundColor green
"---------------------------------------------------------"
