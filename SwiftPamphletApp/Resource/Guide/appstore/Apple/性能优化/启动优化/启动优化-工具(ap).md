# 启动优化：分析工具

启动性能优化，是一个“测量-分析-优化-再测量”的循环过程。在这个过程中，科学的测量和分析工具，是必不可少的。Xcode 和 Instruments 提供了强大的工具链，来帮助我们精确地定位启动性能的瓶颈。

## 1. 测量启动时间

优化的第一步，是获取一个准确的、可量化的启动时间数据。

### 1.1 `DYLD_PRINT_STATISTICS`

这是测量 **pre-main** 阶段耗时的最直接、最权威的工具。

*   **如何开启**: 在 Xcode 的 Scheme 编辑器中，选择 “Run” -> “Arguments”，在 “Environment Variables” 中，添加 `DYLD_PRINT_STATISTICS`，并将其值设置为 `1`。
*   **如何分析**: 设置后，在真机上（非模拟器）运行你的 App。在 Xcode 的控制台输出中，你将看到类似以下的日志：

    ```
    Total pre-main time: 1.3 seconds (100.0%)
           dylib loading time: 324.36 milliseconds (24.1%)
          rebase/binding time: 278.25 milliseconds (20.7%)
              ObjC setup time:  86.30 milliseconds (6.4%)
             initializer time: 654.13 milliseconds (48.7%)
    ```

    这份报告，清晰地列出了 pre-main 阶段各个子过程的耗时：
    *   **dylib loading**: 加载所有动态库所需的时间。**如果这个值过高，说明你的 App 依赖的动态库太多了。**
    *   **rebase/binding**: 对动态库进行重定位和符号绑定所需的时间。动态库越多，这个时间也越长。
    *   **ObjC setup**: Objective-C 运行时的初始化，包括 `+load` 方法的调用、注册类和 `selector` 等。
    *   **initializer**: 执行 C++ 和 Swift 的静态初始化器所需的时间。

### 1.2 MetricKit

MetricKit 是苹果官方的、用于在线上环境，收集和分析性能数据的框架。它可以收集到大量关于启动时间的真实用户数据。

*   **优点**: 能够反映真实用户、在各种不同设备和网络环境下的启动性能，弥补了我们在开发环境中测试的局限性。
*   **核心指标**: `MXAppLaunchMetric` 提供了关于冷启动和热启动时间的详细数据。

### 1.3 手动打点

对于 `main` 函数之后的阶段，我们可以通过手动打点的方式，来测量关键路径的耗时。

```swift
// 在 main.swift 或 AppDelegate 中
let mainStartTime = CFAbsoluteTimeGetCurrent()

// 在 application(_:didFinishLaunchingWithOptions:) 的末尾
let didFinishLaunchingEndTime = CFAbsoluteTimeGetCurrent()
print("didFinishLaunchingWithOptions 耗时: \(didFinishLaunchingEndTime - mainStartTime) 秒")

// 在首屏 ViewController 的 viewDidAppear(_:) 中
let firstScreenEndTime = CFAbsoluteTimeGetCurrent()
print("首屏渲染完成耗时: \(firstScreenEndTime - mainStartTime) 秒")
```

## 2. 分析启动过程

在定位到具体的耗时阶段后，我们需要更深入的工具，来分析具体的瓶颈所在。

### 2.1 Instruments - App Launch

这是 Instruments 中专门用于分析 App 启动过程的模板。它会自动地记录从 App 启动到首屏渲染完成（`viewDidAppear`）这一整个过程中的所有活动。

*   **工作原理**: 它集成了 Time Profiler, System Call Trace, a d App Lifecycle 等多个工具，提供了一个关于启动过程的全景视图。
*   **分析方法**: 
    1.  在 “App Lifecycle” 泳道中，你可以清晰地看到 `pre-main` 和 `main` 阶段的划分，以及 `didFinishLaunching` 等关键生命周期方法的执行时间。
    2.  结合下方的 **Time Profiler**，你可以选中任何一个耗时较长的阶段，然后查看该时间段内，主线程的 CPU 调用栈，从而找到具体的耗时函数。

### 2.2 Instruments - Time Profiler

Time Profiler 是最核心的 CPU 性能分析工具。它可以周期性地对所有线程的调用堆栈进行采样，从而帮助我们找到那些占用 CPU 时间最长的“热点”代码。

*   **使用技巧**: 
    *   **反转调用树 (Invert Call Tree)**: 勾选这个选项，可以让你从最耗时的底层函数，向上回溯，更容易地找到问题的根源。
    *   **隐藏系统库 (Hide System Libraries)**: 勾选这个选项，可以过滤掉大部分的系统函数调用，让你更专注于自己编写的代码。

### 2.3 静态分析工具

*   **Link Map 文件分析**: 通过解析 Link Map 文件，我们可以精确地知道，哪些模块和第三方库，对最终的可执行文件大小贡献最大。这对于优化 `pre-main` 阶段的 `dylib loading` 时间，具有重要的指导意义。
*   **无用代码扫描**: 使用 Periphery 等工具，扫描并移除无用代码，可以直接地减小可执行文件的体积。

## 总结

启动优化，是一个数据驱动的、科学的过程。

1.  **测量 (Measure)**: 首先，使用 `DYLD_PRINT_STATISTICS` 和手动打点，来量化 `pre-main` 和 `main` 阶段的耗时，确定优化的主要矛盾。

2.  **分析 (Profile)**: 其次，使用 **Instruments - App Launch** 和 **Time Profiler**，来深入地分析耗时阶段的函数调用，找到具体的性能瓶颈。

3.  **优化 (Optimize)**: 然后，根据分析结果，采取针对性的优化措施（如减少动态库、异步化、懒加载等）。

4.  **验证 (Verify)**: 最后，再次进行测量，以验证你的优化措施是否有效。

通过熟练地运用这些工具，我们可以将“启动优化”这个看似复杂的工程问题，分解为一个个具体的、可量化、可解决的任务。