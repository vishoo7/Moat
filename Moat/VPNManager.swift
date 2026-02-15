import Foundation
import NetworkExtension

class VPNManager: ObservableObject {
    @Published var isConnected = false
    @Published var isProcessing = false
    @Published var status: NEVPNStatus = .disconnected

    private var manager: NETunnelProviderManager?
    private var statusObserver: Any?

    init() {
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self,
                  let connection = notification.object as? NEVPNConnection,
                  let activeConnection = self.manager?.connection,
                  connection === activeConnection else { return }
            self.updateStatus(connection.status)
        }
        loadConfiguration()
    }

    deinit {
        if let observer = statusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func loadConfiguration() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    print("Failed to load VPN config: \(error.localizedDescription)")
                    return
                }
                self.manager = managers?.first ?? NETunnelProviderManager()
                if let status = self.manager?.connection.status {
                    self.updateStatus(status)
                }
            }
        }
    }

    func saveAndConnect() {
        let manager = self.manager ?? NETunnelProviderManager()
        self.manager = manager
        isProcessing = true

        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = "com.vishal.moat.packettunnel"
        proto.serverAddress = "127.0.0.1"
        proto.disconnectOnSleep = false

        let settings = UserDefaults(suiteName: "group.com.vishal.moat")
        proto.providerConfiguration = [
            "allowMDNS": settings?.object(forKey: "allowMDNS") as? Bool ?? true,
            "allowLocalDNS": settings?.object(forKey: "allowLocalDNS") as? Bool ?? true
        ]

        manager.protocolConfiguration = proto
        manager.localizedDescription = "Moat"
        manager.isEnabled = true

        manager.saveToPreferences { [weak self] error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    print("Failed to save: \(error.localizedDescription)")
                    self.isProcessing = false
                    return
                }
                manager.loadFromPreferences { [weak self] error in
                    DispatchQueue.main.async {
                        guard let self else { return }
                        if let error {
                            print("Failed to reload: \(error.localizedDescription)")
                            self.isProcessing = false
                            return
                        }
                        do {
                            try self.manager?.connection.startVPNTunnel()
                        } catch {
                            print("Failed to start: \(error.localizedDescription)")
                            self.isProcessing = false
                        }
                    }
                }
            }
        }
    }

    func disconnect() {
        manager?.connection.stopVPNTunnel()
    }

    func toggle() {
        if isConnected {
            disconnect()
        } else {
            saveAndConnect()
        }
    }

    private func updateStatus(_ newStatus: NEVPNStatus) {
        status = newStatus
        switch newStatus {
        case .connected:
            isConnected = true
            isProcessing = false
        case .disconnected, .invalid:
            isConnected = false
            isProcessing = false
        case .connecting, .reasserting:
            isConnected = false
            isProcessing = true
        case .disconnecting:
            isConnected = true
            isProcessing = true
        @unknown default:
            break
        }
    }
}
