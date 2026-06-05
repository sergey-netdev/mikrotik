# Fixes the rare issue when handshake cannon be completed
# due to stale "connection" tracking in intermediary firewalls/NAT
# so the response packets go to invalid port
# https://forum.mikrotik.com/t/wireguard-stops-handshaking-out-of-sudden-change-of-port-only-solves-it-for-weeks/175690/81
# Intended for the passive server setup (client peers initiate connections to the server public IP)
# Upload the file to a router, then do
#    /import file=wg-fix.rsc
# It will create a system script and a netwatch monitor

:local wgRemoteIp "10.8.0.1";
:local wgIntfName "wg0";
:local wgScriptName "wg-fix";

# Validation: check if the interface exists
:if ([:len [/interface/wireguard/find name=$wgIntfName]] = 0) do={
	:error ("PVZ: No WireGuard interface '" . $wgIntfName. "' found.")
}

# Validation: attempt to ping the IP
:if ([/ping $wgRemoteIp count=1 interface=$wgIntfName]=0) do={
	:local errorMsg ("PVZ: ". $wgRemoteIp. " failed to ping. Make sure the tunnel is up and the IP does exist.")
	put ("WARNING: ". $errorMsg)
	:log warning $errorMsg
} else={
	put ("PVZ: ". $wgRemoteIp. " ping OK.")
}

#--- Script source start
:local wgFixScript ":local wgRemoteIp \"$wgRemoteIp\";"
:local wgFixScript ($wgFixScript. "\r\n:local wgIntfName \"$wgIntfName\";")
:local wgFixScript ($wgFixScript. "\r\n:log debug \"PVZ: Pinging \$wgRemoteIp via \$wgIntfName...\";")
:local wgFixScript ($wgFixScript. "\r\n:if ([/ping \$wgRemoteIp count=2 interface=\$wgIntfName]=0) do={")
:local wgFixScript ($wgFixScript. "\r\n  :if ([/ping \$wgRemoteIp count=10 interface=\$wgIntfName]=0) do={")
:local wgFixScript ($wgFixScript. "\r\n    :log error \"PVZ: Pinging \$wgRemoteIp via \$wgIntfName failed. Resetting...\";")
:local wgFixScript ($wgFixScript. "\r\n    /interface wireguard set \$wgIntfName listen-port=0")
:local wgFixScript ($wgFixScript. "\r\n}}")
#--- Script source end
put $wgFixScript

/system/script/remove [find name="$wgScriptName"]
/system/script/add name=$wgScriptName comment="$wgScriptName" dont-require-permissions=yes source="$wgFixScript"

put ("Created system script ". $wgScriptName)
:log info ("PVZ: Created system script ". $wgScriptName)

/tool/netwatch/remove [find name=$wgScriptName]
/tool netwatch add comment=$wgScriptName disabled=no host=$wgRemoteIp name=$wgScriptName test-script="$wgScriptName" type=simple
put ("Created netwatch monitor ". $wgScriptName)
:log info ("PVZ: Created netwatch monitor ". $wgScriptName)
