# Enable logs by adding 'script' topic in System -> Logging
:local wan1IntName "ether1";  #WAN1 interface name
:local wan2IntName "ether2";  #WAN2 interface name

:local wan1MonRouteComment "wan1 monitoring";  #WAN1 interface monitoring route label
:local wan2MonRouteComment "wan2 monitoring";  #WAN2 interface monitoring route label

:local wan1DefRouteDistance 1;    #WAN1 interface default route distance (primary)
:local wan2DefRouteDistance 4;    #WAN2 interface default route distance (secondary)

:local wan1MonIp "8.8.8.8"; #WAN1 monitoring IP
:local wan2MonIp "8.8.4.4"; #WAN2 monitoring IP

#--- WAN1 DHCP script start
:local wan1DhcpScript ":if (\$bound = 1) do={"
:local wan1DhcpScript ($wan1DhcpScript. "\r\n  :local gwip \$\"gateway-address\";")
:local wan1DhcpScript ($wan1DhcpScript. "\r\n  :local routeId [/ip route find comment~(\"^" . $wan1MonRouteComment . "\")];")
:local wan1DhcpScript ($wan1DhcpScript. "\r\n  /ip route set \$routeId gateway=\$gwip;")
:local wan1DhcpScript ($wan1DhcpScript. "\r\n}")
:log debug ("PVZ: WAN1 DHCP script to assign: ". $wan1DhcpScript)

:local wan1DhcpId [/ip dhcp-client find where interface=$wan1IntName]
:if ([:len $wan1DhcpId] = 0) do={
    :error ("PVZ: No DHCP client found on interface '" . $wan1IntName. "'.")
} else={
    :log info ("PVZ: Configuring DHCP client on interface '" . $wan1IntName. "'...")
    /ip dhcp-client set $wan1DhcpId add-default-route=no script=$wan1DhcpScript
}
#--- WAN1 DHCP script end

#--- WAN2 DHCP script start
:local wan2DhcpScript ":if (\$bound = 1) do={"
:local wan2DhcpScript ($wan2DhcpScript. "\r\n  :local gwip \$\"gateway-address\";")
:local wan2DhcpScript ($wan2DhcpScript. "\r\n  :local routeId [/ip route find comment~(\"^" . $wan2MonRouteComment . "\")];")
:local wan2DhcpScript ($wan2DhcpScript. "\r\n  /ip route set \$routeId gateway=\$gwip;")
:local wan2DhcpScript ($wan2DhcpScript. "\r\n}")
:log debug ("PVZ: WAN2 DHCP script to assign: ". $wan2DhcpScript)

:local wan2DhcpId [/ip dhcp-client find where interface=$wan2IntName]
:if ([:len $wan2DhcpId] = 0) do={
    :error ("PVZ: No DHCP client found on interface '" . $wan2IntName. "'.")
} else={
    :log info ("PVZ: Configuring DHCP client on interface '" . $wan2IntName. "'...")
    /ip dhcp-client set $wan2DhcpId add-default-route=no script=$wan2DhcpScript
}
#--- WAN2 DHCP script end


:log info ("PVZ: Removing existing routes with comments '" . $wan1MonRouteComment. "' and '" .$wan2MonRouteComment. "'...")
/ip route remove ([/ip route find comment~("^" . $wan1MonRouteComment)])
/ip route remove ([/ip route find comment~("^" . $wan2MonRouteComment)])

:log info ("PVZ: Adding monitoring routes with comments '" . $wan1MonRouteComment. "' and '" .$wan2MonRouteComment. "' to '". $wan1MonIp. "' and '". $wan2MonIp. "'...")
/ip route 
#gateway=0.0.0.0 is OK, it will be replaced by the proper IP by the DHCP script above
add dst-address=$wan1MonIp comment=$wan1MonRouteComment scope=10 gateway=0.0.0.0 
add dst-address=$wan2MonIp comment=$wan2MonRouteComment scope=10 gateway=0.0.0.0

:log info ("PVZ: Re-enabling DHCP clients to trigger the scripts...")
/ip dhcp-client disable $wan1DhcpId
/ip dhcp-client enable $wan1DhcpId
/ip dhcp-client disable $wan2DhcpId
/ip dhcp-client enable $wan2DhcpId
 

:log warning "PVZ: don't forget to add the interfaces to 'WAN' interface list and check the list is added to SRCNAT."

