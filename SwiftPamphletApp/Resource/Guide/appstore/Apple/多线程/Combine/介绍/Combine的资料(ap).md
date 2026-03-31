# Combine 学习资源与参考资料

Combine 的学习曲线相对陡峭，因为它要求开发者彻底转变传统的命令式编程（Imperative Programming）思维，转向声明式的**函数式响应式编程（Functional Reactive Programming, FRP）**。

以下是精选的学习资料，助你跨越这道门槛：

## 1. Apple 官方资源

*   **WWDC19: Introducing Combine**
    *   (必看) 这是 Combine 诞生的发布会 Session。主讲人极其清晰地解释了为什么苹果要开发这个框架，以及 Publisher、Subscriber 和 Operator 的基本概念。
*   **WWDC19: Combine in Practice**
    *   (必看) 这个 Session 展示了如何在实际的 MVC 架构或网络请求中，用 Combine 替换掉传统的代理和通知中心。
*   **官方文档：Using Combine for Your App’s Asynchronous Code**
    *   Apple Developer 文档中一篇极好的长文，详细对比了 Combine 与传统异步模式的差异。

## 2. 社区经典教程

*   **"Using Combine" by Joseph Heck (免费在线书)**
    *   **地址**: *heckj.github.io/swiftui-notes/*
    *   **评价**：这可能是全网**最好**的、完全免费的 Combine 入门到精通教程。作者详细地列出了每一个 Operator 的弹珠图（Marble Diagram），并配有大量可运行的代码示例。
*   **Ray Wenderlich: "Combine: Asynchronous Programming with Swift"**
    *   **评价**：Ray 家的经典红皮书。如果你喜欢按部就班、像教科书一样的阅读体验，并且愿意付费，这本书是不可错过的权威指南。
*   **Fatbobman (肘子的 Swift 记事本)**
    *   **评价**：国内资深开发者。他的博客中有多篇深度剖析 Combine 底层机制和与 SwiftUI 联动的中文文章，非常适合进阶阅读。

## 3. 工具与辅助网站

*   **RxMarbles (rxmarbles.com)**
    *   虽然这是一个针对 RxSwift（RxJS）的网站，但 FRP 的思想是完全互通的。当你不理解 \`merge\`, \`zip\`, \`combineLatest\`, \`flatMap\` 这些复杂操作符的区别时，去这个网站上拖拽一下“弹珠（Marbles）”，观察数据的流向，会瞬间豁然开朗。

## 4. 开源库学习

*   **OpenCombine**
    *   由于 Apple 原生的 Combine 是闭源的，且被绑定在 iOS 13+ 和 macOS 10.15+ 上。社区大神开发了一个开源版本的 OpenCombine（甚至能在 Linux 和老版本 iOS 上运行）。
    *   **学习意义**：如果你想知道底层的 \`Publisher\` 究竟是怎么发送信号的、\`Subscription\` 是如何管理内存生命周期的，直接去读 OpenCombine 的源码是最佳途径。
