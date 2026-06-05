# Fixes the rare issue when handshake cannon be completed
# due to stale "connection" tracking in intermediary firewalls/NAT
# so the response packets go to invalid port
# https://forum.mikrotik.com/t/wireguard-stops-handshaking-out-of-sudden-change-of-port-only-solves-it-for-weeks/175690/81
# Intended for the passive server setup (client peers initiate connections to the server public IP)
# Schedule it in the netwatch:
#	/tool netwatch add comment=wg-fix disabled=no host=10.8.0.1 name=wg-fix test-script="wg-fix" type=simple

# Remote address to ping, wireguard interface name:
:local wgRemoteIp "10.8.0.1";
:local wgIntfName "wg0";

:if ([/ping $wgRemoteIp count=2 interface=$wgIntfName]=0) do={
  :if ([/ping $wgRemoteIp count=10 interface=$wgIntfName]=0) do={
    :log error "$wgIntfName crashed. Resetting.";
    /interface wireguard set $wgIntfName listen-port=0
  }
}
