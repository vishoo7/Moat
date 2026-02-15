import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vpnManager: VPNManager
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                Text("Moat")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                ShieldButton(
                    isActive: vpnManager.isConnected,
                    isProcessing: vpnManager.isProcessing
                ) {
                    vpnManager.toggle()
                }

                VStack(spacing: 8) {
                    Text(statusTitle)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(statusColor)
                        .contentTransition(.numericText())
                        .animation(.easeInOut, value: vpnManager.status)

                    if vpnManager.isConnected {
                        Text("Local network traffic only \u{2022} Internet blocked")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .transition(.opacity)
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    InfoRow(icon: "wifi", text: "LAN & AirPlay still work")
                    InfoRow(icon: "globe", text: "Internet traffic is blocked")
                    InfoRow(icon: "lock.shield", text: "No data leaves your network")
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                Button {
                    showSettings = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var statusTitle: String {
        switch vpnManager.status {
        case .connected: "Protected"
        case .connecting, .reasserting: "Activating..."
        case .disconnecting: "Deactivating..."
        default: "Unprotected"
        }
    }

    private var statusColor: Color {
        switch vpnManager.status {
        case .connected: .cyan
        case .connecting, .reasserting, .disconnecting: .orange
        default: .gray
        }
    }
}

struct ShieldButton: View {
    let isActive: Bool
    let isProcessing: Bool
    let action: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [glowColor.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 60,
                            endRadius: 120
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(pulse ? 1.15 : 1.0)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: isActive
                                ? [Color.cyan.opacity(0.8), Color.teal.opacity(0.6)]
                                : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .overlay(
                        Circle()
                            .stroke(
                                isActive ? Color.cyan.opacity(0.6) : Color.gray.opacity(0.3),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: isActive ? .cyan.opacity(0.4) : .clear, radius: 20)

                Image(systemName: isActive ? "shield.checkered" : "shield.slash")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulse)
        .onChange(of: isProcessing) { _, newValue in
            pulse = newValue
        }
        .sensoryFeedback(.impact(flexibility: .solid), trigger: isActive)
    }

    private var glowColor: Color {
        if isProcessing { return .orange }
        if isActive { return .cyan }
        return .gray
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.cyan)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.gray)
            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(VPNManager())
}
