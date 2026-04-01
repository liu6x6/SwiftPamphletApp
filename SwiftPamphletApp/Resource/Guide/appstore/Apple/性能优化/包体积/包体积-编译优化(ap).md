# 包体积优化：编译与链接优化

除了代码和资源层面的优化，我们还可以通过调整 Xcode 的编译和链接选项，来进一步地压缩我们 App 的最终可执行文件的大小。这些选项，能够指导编译器（Clang/Swiftc）和链接器（ld）在生成最终的二进制文件时，采取更为激进的优化策略。

这些优化，通常只应该在 **Release** 配置下开启，因为它们可能会增加编译时间，或影响调试的便利性。

## 1. 优化级别 (Optimization Level)

这是最重要、也是最基础的编译优化选项。

*   **位置**: `Build Settings -> Swift Compiler - Code Generation -> Optimization Level`
*   **选项**:
    *   **`-Onone`**: 不进行任何优化。这是 Debug 配置下的默认值，它能保证最快的编译速度和最佳的调试体验。
    *   **`-O`**: 优化性能。这是 Release 配置下的默认值。编译器会进行一系列的优化，如函数内联、循环展开等，以提升代码的运行速度。
    *   **`-Osize`**: 优化包体积。编译器会采取所有 `-O` 的优化，但会避免那些可能会显著增加代码体积的优化。**这是包体积优化的首选**。
    *   **`-Ospeed`**: 积极地优化性能，可能会以增加包体积为代价。

## 2. 链接时优化 (Link-Time Optimization, LTO)

LTO 是一种更为激进的、在链接阶段进行的全局优化。

*   **工作原理**: 在常规的编译流程中，每个源文件（`.swift` 或 `.m`）都是被独立编译成一个目标文件（`.o`）。链接器只负责将这些目标文件“粘合”在一起。而在开启 LTO 后，编译器会将源文件编译成一种中间表示形式（LLVM Bitcode）。在最终的链接阶段，链接器可以一次性地看到所有这些中间代码，从而能够进行跨文件的、全局性的优化，例如：
    *   更彻底的函数内联。
    *   更精准的无用代码剥离。
*   **如何开启**: `Build Settings -> Linking -> Link-Time Optimization`
    *   **Incremental (增量式)**: 在 Release 模式下推荐使用。它可以在后续的编译中，只重新编译发生变化的部分，以平衡编译时间和优化效果。
    *   **Monolithic (整体式)**: 会在每次编译时，都对整个项目进行完整的 LTO，优化效果最好，但编译时间也最长。

## 3. 符号剥离 (Symbols Stripping)

可执行文件中，包含了大量的“符号”（Symbols），这些符号是函数名、变量名等信息，主要用于调试。在 Release 版本中，我们可以安全地移除大部分这些符号，以减小体积。

*   **Strip Swift Symbols**: `Build Settings -> Linking -> Strip Swift Symbols`
    *   设置为 `YES`。这会移除所有非 `public` 的 Swift 符号。

*   **Deployment Postprocessing**: `Build Settings -> Deployment -> Deployment Postprocessing`
    *   设置为 `YES`。这会开启一个后处理步骤，其中就包括了对可执行文件的符号剥离。

*   **Strip Linked Product**: `Build Settings -> Linking -> Strip Linked Product`
    *   设置为 `YES`。这会告诉链接器，在链接完成后，运行 `strip` 工具，来移除调试符号。

**注意**: 移除符号，会使得我们无法直接从崩溃日志中，看到具体的函数名。因此，我们必须依赖于在打包时生成的 **dSYM 文件**，来对线上的崩溃日志进行“符号化”。务必确保你的 CI/CD 流程，会自动地、妥善地保存每一个线上版本的 dSYM 文件。

## 4. 其他编译选项

*   **Generate Debug Symbols**: `Build Settings -> Build Options -> Debug Information Format`
    *   在 Release 配置下，应设置为 `DWARF with dSYM File`。这会生成一个独立的 dSYM 文件用于符号化，而不会将调试信息直接编译进二进制文件中。

*   **Dead Code Stripping**: `Build Settings -> Linking -> Dead Code Stripping`
    *   确保在 Release 配置下，该选项被设置为 `YES`。这是进行无用代码剥离的总开关。

## 总结：推荐的 Release 配置

为了最大限度地优化包体积，你的 Release 构建配置，应该至少包含以下设置：

| Build Setting | 推荐值 |
| :--- | :--- |
| **Optimization Level** | `Optimize for Size [-Osize]` |
| **Link-Time Optimization** | `Incremental` |
| **Dead Code Stripping** | `Yes` |
| **Strip Swift Symbols** | `Yes` |
| **Deployment Postprocessing** | `Yes` |
| **Strip Linked Product** | `Yes` |
| **Debug Information Format** | `DWARF with dSYM File` |

通过合理地配置这些编译和链接选项，我们可以在不改变任何代码的情况下，让编译器和链接器自动地为我们完成大量的包体积优化工作。这是一种成本极低、但收益显著的优化手段。