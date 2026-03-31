# Apple 平台：有趣与极客的开源项目

iOS/macOS 开源社区不仅有严肃的商业工具，还有许多充满创意、极客精神甚至略带搞怪的开源项目。研究这些项目能极大地拓宽开发者的技术视野。

## 1. 模拟器与极客工具

*   **Delta**
    *   **简介**：目前 iOS 上最著名、最完善的非越狱复古游戏模拟器（支持 NES, SNES, N64, GBA, DS 等）。它不仅是一个模拟器，其底层的模块化架构非常值得学习。
    *   **学习点**：C/C++ 核心代码与 Swift UI 层的桥接、手柄控制器支持 (\`GameController\` 框架)、Core Data 极其复杂的存档管理。
*   **TrollStore**
    *   **简介**：一个利用 iOS CoreTrust 漏洞实现永久签名侧载的工具。虽然涉及黑客技术，但其源码揭示了 iOS 沙盒与签名机制的底层运作方式。
    *   **学习点**：iOS 逆向工程、Mach-O 文件结构、系统漏洞利用。
*   **UTM**
    *   **简介**：基于 QEMU 的 iOS 和 macOS 虚拟机。它能让你在 iPad 上运行完整的 Windows 10 或 Linux 系统！
    *   **学习点**：底层 JIT 编译（在允许的越狱或特定环境下）、虚拟化框架 (\`Virtualization.framework\`) 的深度使用。

## 2. 视觉与创意交互

*   **fluid-interfaces**
    *   **简介**：详细拆解并完美复刻了 iPhone X 引入的那一套极其丝滑的、基于弹簧物理模型 (Spring Physics) 的全局交互手势。
    *   **学习点**：高级 \`UIPanGestureRecognizer\` 结合 \`UIViewPropertyAnimator\`、投射速度 (Velocity) 计算。
*   **Pock** (macOS)
    *   **简介**：一个让你把 macOS 上的 Dock 栏放进 MacBook Pro 的 Touch Bar 里的极客小工具。
    *   **学习点**：如何 hook macOS 的系统 UI 组件、Touch Bar (\`NSTouchBar\`) 的非标准开发利用。

## 3. "不务正业" 的探索

*   **DoomFire-SwiftUI**
    *   **简介**：仅使用 SwiftUI 绘制和重现了经典游戏《毁灭战士》(DOOM) 底部的火焰粒子渲染算法。
    *   **学习点**：SwiftUI 中极其硬核的 Canvas 和 Shader (Metal) 性能压榨。
