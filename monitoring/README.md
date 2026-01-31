# Monitoring WAN ports

This page complements (2-WAN failover setup)[2-wan-dhcp-failover-rec-route] and enables monitoring of the WAN interfaces.
10.8.0.1 is an IP address of the Wireguard server, where there is (Uptime Kuma)[https://uptimekuma.org/] monitoring server set up at port 3001.

The idea is that a router monitors its WAN interfaces and notifies the monitoring server over the private monitoring WG tunnel.
First we need to create a push monitor in Uptime Kuma via its web interface:


In this example, we create 2 scripts we later will use in Mikrotik's Netwatch.


```
/system script add name=kuma-wan1-heartbeat dont-require-permissions=yes source= {
:local r [/ping 8.8.8.8 count=3 interface=ether1];
:if ($r > 0) do={
    /tool fetch url="http://10.8.0.1:3001/api/push/r7SJHAirF2?status=up&msg=OK" output=none;
} else={
    /tool fetch url="http://10.8.0.1:3001/api/push/r7SJHAirF2?status=down&msg=FAIL" output=none;
}
}

/system script add name=kuma-wan2-heartbeat dont-require-permissions=yes source= {
:local r [/ping 8.8.4.4 count=3 interface=ether2 ];
:if ($r > 0) do={
    /tool fetch url="http://10.8.0.1:3001/api/push/nMLqY6HUnK?status=up&msg=OK" output=none;
} else={
    /tool fetch url="http://10.8.0.1:3001/api/push/nMLqY6HUnK?status=down&msg=FAIL" output=none;
}
}

```
