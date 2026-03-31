# Distributed Actors：突破单机物理边界的并发

在 Swift 5.7 中，Apple 推出了一项极具前瞻性、甚至科幻色彩的技术：**\`Distributed Actors\` (分布式演员模型)**。

如果说普通的 \`actor\` 是为了解决**同一台设备内，不同线程之间**的数据竞争和通信问题；
那么 \`distributed actor\` 就是为了解决**不同设备、不同服务器节点之间**的通信问题。

## 1. 核心理念：位置透明性 (Location Transparency)

在传统的微服务或客户端-服务端通信中，你需要自己写极其复杂的网络层代码（比如基于 HTTP 封装 URL、解析 JSON、处理网络超时和 WebSocket 重连）。

而使用 \`distributed actor\`，**你调用另一台电脑上的函数，就像调用本地内存里的对象一样简单！** 底层的网络通信、序列化/反序列化（Serialization）、甚至 RPC 调用细节，全被编译器和框架给“隐藏（透明化）”了。

## 2. 语法初探

定义一个分布式的 Actor 非常简单，只需加一个 \`distributed\` 关键字：

```swift
import Distributed

// 声明这是一个可以在网络上被远程调用的分布式演员
distributed actor ChatRoom {
    // 演员内部的状态（比如聊天记录），它被隔离在某一台特定的服务器物理机上
    private var messages: [String] = []

    // 提供给外界（比如千里之外的 iPhone 客户端）调用的接口
    // 必须用 distributed 修饰，且参数和返回值必须遵循 Codable (能被网络传输)
    distributed func sendMessage(_ text: String) {
        messages.append(text)
        print("服务器收到了消息: \(text)")
    }
    
    distributed func getMessageCount() -> Int {
        return messages.count
    }
}
```

## 3. 跨越物理边界的调用

假设上述的 \`ChatRoom\` 对象其实是跑在美国的一台 Linux Swift 服务器上的进程。

而在你本地的 iPhone App 代码中，你只拿到了这个对象的**远程身份证 (ID)**。你可以通过系统重建这个远程对象的代理（Proxy）。

```swift
// 在本地的客户端（或另一个服务端节点）代码中：

// 1. 假设你通过某种方式（如配对）拿到了那个远端演员的身份 ID
let remoteRoomID: ChatRoom.ID = // ...

// 2. 根据 ID 解析出一个本地代理对象 (由于网络可能断开，所以用 try 解析)
let remoteChatRoom = try ChatRoom(resolve: remoteRoomID, using: defaultSystem)

Task {
    // 3. 见证奇迹的时刻！
    // 像调用本地对象一样，直接调用远端的函数！
    // 底层会自动把 "Hello" 序列化，通过网络发给美国服务器，服务器执行完后，再把结果通过网络还给你。
    // 这也是为什么所有 distributed 的调用都必须加上 try await（因为网络随时会断，且需要耗时等待）
    do {
        try await remoteChatRoom.sendMessage("Hello from iPhone!")
        let count = try await remoteChatRoom.getMessageCount()
        print("当前服务器有 \(count) 条消息")
    } catch {
        print("RPC 远程调用失败，可能是网断了: \(error)")
    }
}
```

## 4. 传输系统 (ActorSystem)

编译器怎么知道是用 TCP、UDP 还是 WebSocket 来传输这些数据呢？

\`Distributed Actor\` 在设计上是**完全抽象**的。它并不绑定具体的网络协议。开发者需要（或使用第三方提供的库）实现 \`DistributedActorSystem\` 协议。
目前社区中已经有了基于 **WebSocket** 的实现，也有基于 Apple 官方开源的 **Swift Cluster Membership (集群管理)** 框架的高性能游戏服务器传输实现。

## 5. 应用场景与未来

1. **多人实时在线游戏 (MMO)**：服务器端有成千上万个 \`PlayerActor\` 和 \`MonsterActor\`，它们分布在不同的服务器机架上。它们之间互相砍怪、掉血的逻辑，用分布式 Actor 写，代码会极其清晰，彻底告别复杂的 Socket 手写封包。
2. **智能家居 (IoT) 与设备协作**：iPhone 上的 Actor 直接调用 HomePod 上的 Actor 控制音量，底层通过本地局域网的多播协议自动寻址。
