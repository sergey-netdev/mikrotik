# mikrotik-2wan-dhcp-failover-recursive-routes
The script simplifies setting up 2 WAN failover configuration using recursive routes.
Based on https://help.mikrotik.com/docs/spaces/ROS/pages/26476608/Failover+WAN+Backup.

The challenge is that Mikrotik allows to specify an interface as a route gateway, but the route becomes non-recursive. So unfortunatelly, we have to use a helper script in DHCP clients to update the routes' gateway with ISP provided gateway IP:

```
:if ($bound = 1) do={
  :local gwip $"gateway-address";
  :local routeId [/ip route find comment~"^wan1 monitoring"];
  /ip route set $routeId gateway=$gwip distance=4;
}
```
The script scans all routes that have a label starting with "wan1 monitoring" (in the example above) and updates the gateway IP and the distance.

