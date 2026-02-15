import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("allowMDNS", store: UserDefaults(suiteName: "group.com.vishal.moat"))
    var allowMDNS = true

    @AppStorage("allowLocalDNS", store: UserDefaults(suiteName: "group.com.vishal.moat"))
    var allowLocalDNS = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $allowMDNS) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Device Discovery")
                            Text("AirPlay, AirDrop, smart TVs, printers, and other devices on your network")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Toggle(isOn: $allowLocalDNS) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Local Name Lookup")
                            Text("Let your router translate device names to addresses (e.g. \"my-nas.local\")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Allowed Services")
                } footer: {
                    Text("These only affect your local network. Turning them off may prevent some devices from being found or accessed by name. Changes take effect next time you activate Moat.")
                }

                Section("System") {
                    Button("Open App Settings") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                    Text("For VPN controls, open Settings and go to General > VPN & Device Management.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How Moat Works")
                            .font(.headline)
                        Text("Moat sets up a local-only VPN on your device. All internet traffic hits a dead end, while connections to devices on your home network keep working normally. Nothing is collected or sent anywhere — it all stays on your device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
