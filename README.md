# Moat

A local VPN for iOS that blocks all internet traffic while keeping your local network fully accessible. Think of it as airplane mode — but your LAN still works.

## Why Moat?

### You don't know what your apps are doing

When you open an app that talks to devices on your local network — your Bitcoin node, your NAS, your home server — you're trusting that the app *only* talks to your local network. But you have no way to verify that. The app could be phoning home, exfiltrating data, or leaking details about your setup to remote servers, all while you interact with it locally.

**Moat makes this a non-issue.** Turn it on, and internet traffic simply cannot leave your device. Your LAN connections work exactly as before — but nothing gets out to the public internet. No DNS leaks, no background telemetry, no silent data exfiltration.

### Keep kids on your network, not the internet

Moat is also great for families. Let your kids access local media servers, AirPlay to the TV, or use network-connected apps — without any exposure to the open internet. No surprise notifications from social apps, no accidental browsing, no content you didn't intend them to see. Just your home network.

## How It Works

Moat creates an on-device VPN that captures all outbound traffic through a packet tunnel. Local network ranges (192.168.x.x, 10.x.x.x, etc.) are excluded from the tunnel and routed normally. Everything else — all internet-bound traffic — enters the tunnel and is silently dropped.

- **LAN traffic** → bypasses the tunnel → works normally
- **Internet traffic** → enters the tunnel → blackholed
- **mDNS/Bonjour** → excluded → AirPlay, AirDrop, and device discovery work
- **DNS** → pointed at a dead end so public lookups fail; local DNS can still resolve

No remote servers. No accounts. No data collection. Everything runs entirely on your device.

## Setup

1. Open `Moat.xcodeproj` in Xcode
2. Set your Development Team for both the **Moat** and **MoatPacketTunnel** targets under Signing & Capabilities
3. Enable the **Network Extensions** capability (Packet Tunnel) for both targets
4. Build and run on a physical iOS device (VPN extensions don't work in the simulator)
5. Tap the shield to activate — iOS will prompt you to approve the VPN configuration on first use

### Requirements

- iOS 17.0+
- Xcode 15+
- Apple Developer account (paid — required for the Network Extension entitlement)

## Project Structure

```
Moat/
├── Moat/                           Main app target
│   ├── MoatApp.swift               SwiftUI entry point
│   ├── ContentView.swift           Shield toggle UI
│   ├── VPNManager.swift            NETunnelProviderManager wrapper
│   ├── SettingsView.swift          mDNS/DNS toggles
│   └── Moat.entitlements
├── MoatPacketTunnel/               Network Extension target
│   ├── PacketTunnelProvider.swift   Packet tunnel implementation
│   └── MoatPacketTunnel.entitlements
└── Moat.xcodeproj
```

## Troubleshooting

### Brave, Firefox, or other browsers can't load local pages

Some browsers use their own **Secure DNS (DNS over HTTPS)** instead of your system's DNS settings. This means they try to reach public DNS servers like Cloudflare or Google to resolve addresses — which Moat blocks.

**Safari** uses the system DNS resolver and works out of the box.

**For Brave:** go to `brave://settings/security`, find "Use secure DNS", and either turn it off or switch to "With your current service provider."

**For Firefox:** go to `about:preferences#privacy`, scroll to "DNS over HTTPS", and set it to "Off."

Other Chromium-based browsers (Edge, Arc, etc.) have similar settings under their security/privacy preferences.

### The VPN won't start

Make sure you've approved the VPN configuration when iOS prompts you. You can check under **Settings → General → VPN & Device Management** on your device.

## Disclaimer

Moat blocks internet traffic only while the VPN is active. Once you turn Moat off, apps can resume normal network activity including any outbound connections. For maximum protection, keep Moat enabled whenever you're using apps that should stay local-only.
