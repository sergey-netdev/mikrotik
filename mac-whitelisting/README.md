This article describes how to setup MAC address restriction for Mikrotik clients so any client that needs to connect to the network must be whitelisted first. This works for both wired and wireless clients.

# Prerequisites

Make your current DHCP lease static:
<p><img src="screenshot-lease-static.png" alt="DHCP lease edit" width="80%"/></p>

To not lock yourself out in future, create an emergency entry. This is also useful when a new support personnel doesn't have his entry, yet. In this case he would specify 00:01:02:03:04:05 MAC manually in his laptop's interface and gain access to the router.

Assuming your network is 192.168.88.1/24:
```
    
    /ip dhcp-server lease add address="192.168.88.2" mac-address="00:01:02:03:04:05" server="dhcp1" comment="Emergency connect" disabled=no
    /ip arp add address="192.168.88.2" mac-address="00:01:02:03:04:05" interface="bridge1" comment="Emergency connect"
}
```
Here we reserve 192.168.88.2 and bind it to 00:01:02:03:04:05 MAC.

# Configuring the router
Since we're managing the ARP table and DHCP leases manually, enable this on your LAN bridge/DHCP.

Modify the names, then copy-paste it into your Mikrotik's terminal:
```
:do{
    :local bridgeName "bridge1"; # Your bridge name
    :local dhcpSrvName "dhcp1";  # Name of your DHCP server linked to the bridge
    /interface bridge set [find name=$bridgeName] arp=reply-only
    /ip dhcp-server set [find name=$dhcpSrvName] add-arp=yes
}
```
Once this is done, you have to whitelist any client by creating a lease *and* the ARP entry for it (you can reuse the script we used to create the emergency entry above).

# The flow
 1. Obtain the client MAC address (ask the device owner). Note (!), dual-interface WiFi clients have 2 separate MAC addresses! Both addresses must be whitelisted.
 2. Connect to the router using Winbox
 3. Add a static lease entry (IP -> DHCP server -> Leases) for the MAC. Specify the device owner in the comment. <p><img src="screenshot-leases.png" alt="DHCP leases" width="80%" /></p> <p><img src="screenshot-lease-edit.png" alt="DHCP lease edit" width="30%"/></p>
 4. Add the corresponding ARP entry. Specify the device owner in the comment. <p><img src="screenshot-arp.png" alt="DHCP leases" width="80%" /></p>


DHCP still works and will provide the client with DNS server, etc. However, it's constrained to a specific MAC and IP address only.
