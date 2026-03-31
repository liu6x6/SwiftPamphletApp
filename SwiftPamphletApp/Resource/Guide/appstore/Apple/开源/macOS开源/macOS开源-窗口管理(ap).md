# macOS 开源：窗口管理工具 (Window Management)

与 Windows 操作系统自带极其强大的贴边吸附（Snap）和多窗口平铺功能不同，macOS 原生的窗口管理一直比较羸弱（直到 macOS 15 Sequoia 才有所改善）。因此，第三方窗口管理工具（如 Magnet, Rectangle）在 Mac 上是极其庞大的刚需市场。

GitHub 上有大量非常优秀的开源窗口管理器，它们是学习 **macOS 无障碍辅助 API (Accessibility API)** 和 **系统级快捷键** 编程的终极宝库。

## 1. 顶级开源窗口管理器

*   **Rectangle**
    *   **简介**：可以说是目前 macOS 上最知名、使用最广泛的开源窗口管理器。你可以通过快捷键或将窗口拖拽到屏幕边缘，瞬间让窗口占据屏幕的一半或四分之一。
    *   **学习点**：这是学习窗口控制的绝对标杆项目。

*   **Amethyst**
    *   **简介**：另一款老牌的开源平铺式窗口管理器。
    *   **学习点**：支持更复杂的多显示器焦点切换和窗口阵列布局算法。

*   **Yabai**
    *   **简介**：一个平铺式（Tiling）窗口管理器，灵感来自 Linux 上的 bspwm。它不需要你手动拖拽，一旦打开新窗口，系统会自动计算并平铺所有窗口，不留一丝缝隙。
    *   **学习点**：极其硬核的底层 Hook 和脚本化控制机制。

## 2. 核心技术揭秘：Accessibility (AX) API

macOS 出于安全和沙盒的考虑，绝不允许一个 App 随意获取甚至修改另一个 App 的界面大小和位置。

当你阅读 Rectangle 等项目的源码时，你会发现它们全部依赖于 **\`CoreGraphics\`** 和 **\`ApplicationServices\` (特别是 AX API)**。

### 步骤 A：获取系统无障碍权限
这类软件启动的第一步，就是通过 \`AXIsProcessTrusted()\` 检查自己是否拥有“辅助功能”权限，如果没有，会弹窗要求用户前往“系统设置”勾选。

### 步骤 B：获取目标窗口的引用
使用 \`NSWorkspace.shared.frontmostApplication\` 获取当前活跃的 App，然后通过 \`AXUIElementCreateApplication\` 创建一个代表该应用的无障碍元素节点。接着遍历它的子节点，找到处于聚焦状态的主窗口 (Focused Window)。

### 步骤 C：修改窗口的 Frame (坐标与尺寸)
这需要用到复杂的 C 语言风格函数：
```swift
// 伪代码演示底层逻辑
let axWindow: AXUIElement = // ...获取到的窗口节点
var newPosition = CGPoint(x: 0, y: 0) // 设置到左上角
var newSize = CGSize(width: screenWidth / 2, height: screenHeight) // 设置为屏幕左半边

// 必须将 Swift 结构体转换为 CFType
let positionValue = AXValueCreate(.cgPoint, &newPosition)!
let sizeValue = AXValueCreate(.cgSize, &newSize)!

// 发送系统指令，强制修改目标窗口的位置和大小
AXUIElementSetAttributeValue(axWindow, kAXPositionAttribute as CFString, positionValue)
AXUIElementSetAttributeValue(axWindow, kAXSizeAttribute as CFString, sizeValue)
```

## 3. 多显示器 (Displays) 适配算法

窗口管理的另一个技术难点是应对多显示器环境。
*   你需要学习如何通过 \`NSScreen.screens\` 获取所有连接的显示器。
*   如何正确计算每个显示器的 \`visibleFrame\`（必须扣除掉顶部菜单栏和底部 Dock 栏占据的盲区）。
*   当用户按下“将窗口移动到下一个显示器”的快捷键时，如何将前一个显示器的相对比例（比如原本占右半边）完美映射到分辨率完全不同的另一个显示器上。
