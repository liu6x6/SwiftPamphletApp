# macOS 开源：菜单栏 (Menu Bar) 工具

在 macOS 顶部的右上角，有一排常驻的小图标，它们被称为“菜单栏应用”（Menu Bar Apps 或 Status Bar Apps）。由于它们无需在 Dock 栏显示，且能随时快速呼出，深受开发者和用户的喜爱。

GitHub 上有大量的开源菜单栏小工具，它们是学习 macOS 极简交互设计的极佳素材。

## 1. 著名的开源菜单栏工具

*   **Maccy**
    *   **简介**：一款极其轻量、速度极快的剪贴板历史记录管理器。
    *   **学习点**：
        *   如何监听 macOS 全局的 \`NSPasteboard\` 变化。
        *   如何构建一个支持全键盘操作（通过方向键选择、回车粘贴）的极速菜单列表。
        *   全局快捷键（Hotkeys）的注册机制。

*   **Hidden Bar / Dozer**
    *   **简介**：像 Bartender 一样，帮助你折叠和隐藏过多的菜单栏图标。
    *   **学习点**：涉及一些针对 macOS UI 树的非标准操作，如何控制同级别其他 \`NSStatusItem\` 的显示和隐藏。

*   **Itsycal**
    *   **简介**：一个极其小巧的、点击直接展开日历面板的菜单栏工具。
    *   **学习点**：如何将一个普通的 \`NSViewController\` 包装进弹出框（\`NSPopover\`）中，并将其锚定在菜单栏图标的正下方。

## 2. 菜单栏开发的核心 API：\`NSStatusItem\`

阅读这些开源项目的源码，你会发现它们都围绕着 AppKit 的 \`NSStatusItem\` 展开。

### 基础实现逻辑：
1.  在 \`AppDelegate\` 启动时，不要创建主窗口（甚至在 Info.plist 中设置 \`LSUIElement = YES\` 以隐藏 Dock 图标）。
2.  通过 \`NSStatusBar.system.statusItem(withLength:)\` 向系统申请一个菜单栏位置。
3.  设置其显示的图标 (\`button.image\`)。

### 两种交互模式：
这些开源项目通常展示了两种处理用户点击的方式：
*   **模式 A：原生下拉菜单 (Menu)**：给 \`statusItem.menu\` 赋值一个 \`NSMenu\`。点击后会弹出像系统 Wi-Fi 或蓝牙那样的标准菜单条目。
*   **模式 B：自定义弹窗 (Popover)**：不使用系统菜单，而是监听点击事件，然后利用 \`NSPopover\` 弹出一个包含了任意复杂视图（如 SwiftUI View）的浮动窗口面板。

## 3. 结合 SwiftUI 的现代开发方式

较新的开源项目（如针对 macOS 12+ 编写的）展示了如何使用纯 SwiftUI 的 \`MenuBarExtra\` 协议来极简地构建菜单栏应用，彻底抛弃了繁琐的 \`AppDelegate\` 和 \`NSStatusItem\` 的管理代码。

```swift
@main
struct MenuBarApp: App {
    var body: some Scene {
        MenuBarExtra("实用工具", systemImage: "hammer") {
            Button("功能 1") { }
            Button("功能 2") { }
            Divider()
            Button("退出") { NSApplication.shared.terminate(nil) }
        }
    }
}
```
通过学习这些开源项目，你可以快速掌握如何在 macOS 上构建一个常驻后台、优雅小巧的效率工具。
