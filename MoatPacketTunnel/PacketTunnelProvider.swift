import NetworkExtension
import os

class PacketTunnelProvider: NEPacketTunnelProvider {

    private let log = Logger(subsystem: "com.vishal.moat.packettunnel", category: "tunnel")

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        log.info("Starting tunnel...")

        let config = (protocolConfiguration as? NETunnelProviderProtocol)?.providerConfiguration
        let allowMDNS = config?["allowMDNS"] as? Bool ?? true
        let allowLocalDNS = config?["allowLocalDNS"] as? Bool ?? true

        // Use 198.18.0.1 (benchmarking range) to avoid conflicts with common LAN subnets
        let tunnelAddress = "198.18.0.1"

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")

        // MARK: - IPv4

        let ipv4 = NEIPv4Settings(addresses: [tunnelAddress], subnetMasks: ["255.255.255.0"])

        // Capture ALL traffic through the tunnel
        ipv4.includedRoutes = [NEIPv4Route.default()]

        // Exclude private/LAN ranges so they bypass the tunnel
        var excludedRoutes: [NEIPv4Route] = [
            NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
            NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
            NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
            NEIPv4Route(destinationAddress: "169.254.0.0", subnetMask: "255.255.0.0"),
            NEIPv4Route(destinationAddress: "255.255.255.255", subnetMask: "255.255.255.255"),
        ]

        if allowMDNS {
            excludedRoutes.append(
                NEIPv4Route(destinationAddress: "224.0.0.0", subnetMask: "240.0.0.0")
            )
        }

        ipv4.excludedRoutes = excludedRoutes
        settings.ipv4Settings = ipv4

        // MARK: - IPv6

        let ipv6 = NEIPv6Settings(addresses: ["fd00::1"], networkPrefixLengths: [128])
        ipv6.includedRoutes = [NEIPv6Route.default()]

        var excludedIPv6Routes: [NEIPv6Route] = [
            NEIPv6Route(destinationAddress: "fc00::", networkPrefixLength: 7),
            NEIPv6Route(destinationAddress: "fe80::", networkPrefixLength: 10),
        ]

        if allowMDNS {
            excludedIPv6Routes.append(
                NEIPv6Route(destinationAddress: "ff00::", networkPrefixLength: 8)
            )
        }

        ipv6.excludedRoutes = excludedIPv6Routes
        settings.ipv6Settings = ipv6

        // MARK: - DNS

        if allowLocalDNS {
            // Point DNS to the tunnel address to blackhole public DNS,
            // but use matchDomains = [""] so the system can still fall back
            // to local DNS servers for LAN resolution.
            let dns = NEDNSSettings(servers: [tunnelAddress])
            dns.matchDomains = [""]
            settings.dnsSettings = dns
        } else {
            // Fully blackhole DNS
            let dns = NEDNSSettings(servers: [tunnelAddress])
            settings.dnsSettings = dns
        }

        settings.mtu = 1400

        setTunnelNetworkSettings(settings) { [weak self] error in
            if let error {
                self?.log.error("Failed to set tunnel settings: \(error.localizedDescription)")
                completionHandler(error)
                return
            }
            self?.log.info("Tunnel started successfully")
            self?.drainPackets()
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        log.info("Stopping tunnel, reason: \(reason.rawValue)")
        completionHandler()
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        if let config = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any] {
            log.info("Received app message: \(config.description)")
        }
        completionHandler?(nil)
    }

    /// Read and discard packets entering the tunnel (internet-bound traffic).
    /// Prevents the tunnel buffer from filling up.
    private func drainPackets() {
        packetFlow.readPackets { [weak self] _, _ in
            self?.drainPackets()
        }
    }
}
