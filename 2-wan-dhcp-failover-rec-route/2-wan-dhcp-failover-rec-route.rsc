# DO NOT copy-paste the script into Mikrotik terminal!
# Instead, modify the params, upload it to the router and execute with `import file-name=2-wan-dhcp-failover-rec-route.rsc`
#
# !!! PREREQUISITES !!! Assuming your Mikrotik has the configuration close to the default one:
#	'WAN' interface list masqueraded, no static defaul routes, WAN interfaces enabled, etc.

# [OPTIONAL] Choose your WAN1 and WAN2 interfaces, update the following variables, if needed:
:local wan1IntName "ether1";  #WAN1 interface name
:local wan2IntName "ether2";  #WAN2 interface name
:local wanIntList  "WAN"

# [REQUIRED] Create DHCP clients for both interfaces manually, if not yet, and test if they get the gateway IPs
# [OPTIONAL] Enable logs by adding 'script' and 'dhcp' topics in System -> Logging

# [OPTIONAL] Update the following monitoring IPs. They MUST BE DIFFERENT. For example, 8.8.8.8 for WAN1 and 8.8.4.4 WAN2
:local wan1MonIp "8.8.8.8"; #WAN1 monitoring IP
:local wan2MonIp "8.8.4.4"; #WAN2 monitoring IP

# [OPTIONAL] Update other parameters
:local wan1MonRouteComment "wan1 monitoring";  #WAN1 interface monitoring route comment
:local wan2MonRouteComment "wan2 monitoring";  #WAN2 interface monitoring route comment
:local wan1DefRouteDistance 1;    #WAN1 interface default route distance (primary)
:local wan2DefRouteDistance 4;    #WAN2 interface default route distance (secondary)

# Run the script, check the logs for possible errors.

:if ([:len [/interface bridge port find interface=$wan1IntName]] > 0) do={
    :error ("Interface '" . $wan1IntName . "' is not expected to be a part of any bridge. If it must, disable the check in the script.")
}
:if ([:len [/interface bridge port find interface=$wan2IntName]] > 0) do={
    :error ("Interface '" . $wan2IntName . "' is not expected to be a part of any bridge. If it must, disable the check in the script.")
}


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


:log info ("PVZ: Removing existing monitoring routes '" . $wan1MonRouteComment. "' and '" .$wan2MonRouteComment. "'...")
/ip route remove ([/ip route find comment~("^" . $wan1MonRouteComment)])
/ip route remove ([/ip route find comment~("^" . $wan2MonRouteComment)])

:log info ("PVZ: Adding monitoring routes with comments '" . $wan1MonRouteComment. "' and '" .$wan2MonRouteComment. "' to '". $wan1MonIp. "' and '". $wan2MonIp. "'...")
# No need to specify gateway in the routes, it will be replaced with the proper IP by the DHCP scripts
/ip route 
add dst-address=$wan1MonIp comment=$wan1MonRouteComment scope=10
add dst-address=$wan2MonIp comment=$wan2MonRouteComment scope=10

# Now we have the monitoring routes and need to force trigger the DHCP client scripts
:log info ("PVZ: Re-enabling DHCP clients to trigger the scripts...")
:foreach dhcpId in=($wan1DhcpId, $wan2DhcpId) do={
    /ip dhcp-client disable $dhcpId
    /ip dhcp-client enable $dhcpId
}

:log info "PVZ: Removing existing default routes..."
/ip route remove ([/ip route find gateway=$wan1MonIp])
/ip route remove ([/ip route find gateway=$wan2MonIp])

:log info "PVZ: Adding default recursive routes..."
/ip/route/
add distance=$wan1DefRouteDistance gateway=$wan1MonIp target-scope=11 check-gateway=ping comment=("WAN1 via ". $wan1MonIp)
add distance=$wan2DefRouteDistance gateway=$wan2MonIp target-scope=11 check-gateway=ping comment=("WAN2 via ". $wan2MonIp)

# check if interface list exists
:log info ("PVZ: Checking if '". $wanIntList. "' interface list exists...")
:if ([:len [/interface list find name=$wanIntList]] > 0) do={

    :if ([:len [/interface list member find list=$wanIntList interface=$wan1IntName]] = 0) do={
        :log info ("PVZ: Adding interface '". $wan1IntName. "' to '". $wanIntList. "' interface list.")
        /interface list member add list=$wanIntList interface=$wan1IntName
    }
    :if ([:len [/interface list member find list=$wanIntList interface=$wan2IntName]] = 0) do={
        :log info ("PVZ: Adding interface '". $wan2IntName. "' to '". $wanIntList. "' interface list.")
        /interface list member add list=$wanIntList interface=$wan2IntName
    }

    # Check if there is at least one SRCNAT rule using this interface list
    :if ([:len [/ip firewall nat find chain=srcnat out-interface-list=$wanIntList]] > 0) do={
        :log info ("PVZ: There is SRCNAT for interface list '" .$wanIntList. "'. Good.")
    } else= {
        :log warning ("PVZ: NO SRCNAT for interface list '" .$wanIntList. "'. Don't forget to configure your SRCNAT!")
    }
} else={
    :log warning ("PVZ: Interface list '". $wanIntList. "' not found. Don't forget to configure your SRCNAT!")
}

:log info "PVZ: All done!"
