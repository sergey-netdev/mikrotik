
ROS 7 removed `add-arp` option at leases level, now it's an option of DHCP servers.
The recommended solution is to use Lease Script:
```
system script add name=dhcp-arp-inject source={
:local mac $leaseActMAC
:local ip $leaseActAddress
:local intf $leaseActInterface

# Skip if entry already exists
:if ([:len [/ip arp find address=$ip interface=$intf]] = 0) do={
    /ip arp add address=$ip mac-address=$mac interface=$intf
}
}
```
attached to a DHCP server:
```
/ip dhcp-server set [find name="dhcp1"] lease-script=dhcp-arp-inject
```

# The flow
 1. Obtain the client MAC address (ask the device owner). Note, dual-interface WiFi clients have 2 separate MAC addresses!
 2. Add a lease entry (IP -> DHCP server -> Leases) for the MAC(s). The script will add the corresponding ARP entry
 3. 
 
 
