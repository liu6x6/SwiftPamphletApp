# iOS/macOS 系统能力：网络扩展 (Network Extension)

网络扩展（Network Extension）框架是苹果提供的一套强大的 API，用于在系统级别对网络流量进行监控、过滤和隧道化。它允许开发者创建特定类型的应用扩展，来实现以往只有在越狱设备上才能实现的高级网络功能。

这套框架是构建 VPN 客户端、内容过滤器、广告拦截器、DNS 代理等网络工具应用的基础。

## 核心概念：应用扩展与系统权限

网络扩展是一种特殊类型的应用扩展（App Extension），它运行在一个独立的、具有更高系统权限的进程中。由于它能接触到用户设备上所有应用的网络流量，因此它的开发和分发受到苹果的严格管控。

要使用网络扩展，你必须：
1.  在你的 Apple Developer 账户中，为你的 App ID 申请并启用相应的网络扩展权限（例如 “Personal VPN” 或 “Network Content Filter”）。
2.  在 Xcode 项目的 “Signing & Capabilities” 中，添加对应的能力。

## 网络扩展的主要类型

`NetworkExtension` 框架主要提供了以下几种类型的扩展：

### 1. VPN 扩展 (`NEVPNManager`)

这是用于创建 VPN 客户端的核心。它允许你建立一个到远程服务器的、安全的网络隧道，并将设备的全部或部分网络流量通过这个隧道进行路由。

*   **协议**: 你可以实现标准的 VPN 协议，如 `IPSec` 和 `IKEv2`。`NEVPNManager` 提供了配置这些协议的 API。
*   **自定义协议 (Packet Tunnel Provider)**: 如果你需要实现一个私有的、非标准的 VPN 协议（例如 Shadowsocks, WireGuard），你需要创建一个 **Packet Tunnel Provider** 扩展。你需要遵循 `NEPacketTunnelProvider` 协议，并实现其方法来处理底层的网络数据包（IP packets）的读取、加密、发送、接收和解密。

### 2. DNS 代理 (`NEDNSProxyProvider`)

DNS 代理扩展允许你截获设备上所有的 DNS 查询请求。你可以：
*   将 DNS 查询重定向到你自己的、安全的 DNS 服务器（如 DNS-over-HTTPS 或 DNS-over-TLS）。
*   根据自定义规则，过滤或修改 DNS 查询结果，例如实现广告拦截或家长控制。

### 3. 内容过滤器 (`NEFilterDataProvider` & `NEFilterControlProvider`)

内容过滤器扩展用于在设备上实时地监控和过滤网络流量。它主要有两种形式：
*   **`NEFilterDataProvider`**: 用于实现一个设备上的网络内容过滤器。它可以检查流经设备的 TCP 连接和 UDP 流，并根据一套规则来决定是允许还是阻止这些流量。常用于实现防火墙或恶意软件拦截。
*   **`NEFilterControlProvider`**: 用于与 `NEFilterDataProvider` 配合，提供一个用户界面来配置和管理过滤规则。

## 实现一个 Packet Tunnel Provider (VPN)

创建一个自定义的 VPN 客户端是网络扩展最常见的用途之一。

1.  **添加 Target**: 在 Xcode 中，添加一个新的 “Packet Tunnel Provider” Target。

2.  **创建 `NEPacketTunnelProvider` 子类**: Xcode 会为你生成一个 `PacketTunnelProvider` 类。你需要在这个类中实现核心的隧道逻辑。

    ```swift
    import NetworkExtension
    
    class PacketTunnelProvider: NEPacketTunnelProvider {
    
        override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
            // 1. 建立到你的 VPN 服务器的连接
            // ...
            
            // 2. 创建一个 NEPacketTunnelNetworkSettings 对象，配置隧道的 IP 地址和 DNS 设置
            let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "...")
            networkSettings.ipv4Settings = ...
            networkSettings.dnsSettings = ...
            
            // 3. 应用网络设置，这会创建一个虚拟的网络接口 (utun)
            setTunnelNetworkSettings(networkSettings) { error in
                if let error = error {
                    completionHandler(error)
                    return
                }
                
                // 4. 成功建立隧道，开始读取和写入 IP 数据包
                completionHandler(nil)
                startReadingPackets()
            }
        }
        
        func startReadingPackets() {
            // 从虚拟网络接口 (packetFlow) 读取 IP 数据包
            packetFlow.readPackets { (packets, protocols) in
                for packet in packets {
                    // 在这里对数据包进行加密，然后通过你建立的服务器连接发送出去
                }
                // 递归调用以持续读取
                self.startReadingPackets()
            }
        }
        
        override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
            // 关闭到服务器的连接，清理资源
            completionHandler()
        }
    }
    ```

3.  **主应用的职责**: 你的主应用（容器 App）负责：
    *   向用户显示 UI，例如一个“连接”按钮。
    *   使用 `NEVPNManager` 来加载、配置和控制你的 VPN 扩展。

    ```swift
    NEVPNManager.shared().loadFromPreferences { error in
        // ...
        let p = NEVPNProtocolIPSec() // 或其他协议
        // ... 配置协议
        manager.protocolConfiguration = p
        manager.isEnabled = true
        manager.saveToPreferences { error in
            // ...
            try? manager.connection.startVPNTunnel()
        }
    }
    ```

## 调试网络扩展

调试网络扩展比调试普通应用更复杂，因为它运行在一个独立的进程中。

1.  在 Xcode 中，选择你的网络扩展的 Scheme 并运行它。Xcode 会提示你选择一个宿主应用来启动（通常是你的主应用）。
2.  在你的主应用中，执行触发扩展启动的代码（例如，点击“连接 VPN”按钮）。
3.  Xcode 的调试器会自动附加到你的网络扩展进程上，你就可以像调试普通应用一样设置断点和检查变量了。
4.  你可以在 macOS 的“控制台 (Console.app)”应用中，通过过滤你的扩展进程名，来查看 `os_log` 输出的日志。

## 总结

网络扩展（Network Extension）框架是 iOS 和 macOS 上进行底层网络编程的唯一官方途径。它为开发者提供了前所未有的能力，可以直接与系统的网络堆栈进行交互。

*   **功能强大**: 支持 VPN、DNS 代理、内容过滤等多种高级网络功能。
*   **权限严格**: 需要在 Apple Developer 网站上申请特殊权限，并由用户明确授权。
*   **独立进程**: 扩展运行在独立的、具有更高权限的进程中。
*   **核心协议**: `NEPacketTunnelProvider`, `NEDNSProxyProvider`, `NEFilterDataProvider` 是实现不同类型扩展的关键。

开发网络扩展具有很高的技术门槛，需要对网络协议（TCP/IP, DNS 等）和系统编程有深入的理解。然而，它也是构建下一代网络安全、隐私保护和网络工具应用的基石。
