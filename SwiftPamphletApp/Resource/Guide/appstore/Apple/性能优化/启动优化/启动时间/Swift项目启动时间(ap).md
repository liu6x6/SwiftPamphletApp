# Swift 项目启动时间分析

对于以 Swift 为主要开发语言的项目，其启动时间的分析和优化，既遵循通用的 `pre-main` 和 `main` 阶段划分，也因 Swift 语言自身的静态化、值类型、泛型等特性，而呈现出与 Objective-C 项目不同的侧重点。

## pre-main 阶段的耗时分析

在 Swift 项目中，`pre-main` 阶段的耗时，同样可以通过设置环境变量 `DYLD_PRINT_STATISTICS` 为 `1` 来进行测量。其主要构成部分包括：

### 1. dylib loading (动态库加载)

*   **原因**: 动态链接器（`dyld`）需要加载 App 所依赖的所有动态库。**动态库的数量，是影响这一阶段耗时的最主要因素。**
*   **Swift 项目的特点**: Swift 的标准库（`libswiftCore.dylib` 等）是以动态库的形式，存在于操作系统中的。从 iOS 12.2 开始，这些标准库已经成为了系统的一部分，无需再打包进 App 中，极大地减小了 Swift App 的体积。然而，对于我们自己创建的、或通过第三方依赖管理的动态库，其加载开销依然存在。
*   **优化**: 
    *   **核心原则**: **尽可能地减少自定义动态库的数量。**
    *   **静态链接**: 将第三方依赖和业务模块，尽可能地改为静态链接。
    *   **可合并库 (Mergeable Libraries)**: 对于必须使用动态库的场景，可以开启此功能，将多个动态库，在链接时自动合并成一个。

### 2. rebase/binding (重定位/绑定)

*   **原因**: `dyld` 需要修正代码中所有指向外部动态库符号的地址。
*   **Swift 项目的特点**: Swift 倾向于使用**静态派发**（对于 `struct` 和 `final class` 的方法）和**虚表派发**（v-table，对于非 `final` 的 `class` 方法），而不是像 Objective-C 那样，大量地依赖于基于字符串的 `selector` 动态绑定。这使得 Swift 代码在链接时，需要进行的符号绑定（Binding）数量，通常会少于同等规模的 OC 项目。
*   **优化**: 核心仍然是**减少动态库的数量**。

### 3. ObjC setup (Objective-C 运行时设置)

*   **原因**: 即使是纯 Swift 项目，也仍然需要与 Objective-C 的运行时进行互操作（例如，继承自 `NSObject` 的类，或者使用 UIKit/AppKit 框架）。因此，这一阶段的耗时依然存在。
*   **优化**: 
    *   **减少继承自 `NSObject` 的类**: 除非必要（例如，需要 KVC/KVO），否则优先使用纯 Swift 的 `class` 或 `struct`。
    *   **避免 `@objc`**: 只有在需要将 Swift API 暴露给 Objective-C 运行时（例如，用于 `selector`）时，才使用 `@objc` 关键字。

### 4. initializers (初始化器)

*   **原因**: `dyld` 需要执行所有的静态初始化器。
*   **Swift 项目的特点**: Swift 中没有 `+load` 方法。全局变量和静态变量的初始化，是**懒加载**的（lazy），即在它们第一次被访问时，才会被执行。这从根本上，避免了 OC 项目中 `+load` 方法堆积在启动阶段的问题。
*   **潜在风险**: 需要注意那些在 App 一启动，就会被立即访问到的全局变量。应该避免在这些变量的初始化器中，进行复杂的、耗时的操作。

## main 阶段的耗时分析

`main` 阶段的优化，核心是**延迟和异步**，其原则与 OC 项目基本一致。

*   **`application(_:didFinishLaunchingWithOptions:)` 的瘦身**: 
    *   只保留与首屏渲染直接相关的、必须同步执行的代码。
    *   将所有非首屏必须的初始化工作，都异步地派发到后台线程。

*   **Swift Concurrency 的应用**: 
    *   使用 `Task.detached(priority:)`，可以非常方便地，将不同优先级的初始化任务，派发到后台执行。
    *   对于需要依赖关系的任务，可以使用 `async let` 来进行并发初始化，然后用 `await` 等待它们的结果。

    ```swift
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // ...
        Task.detached(priority: .background) {
            await setupThirdPartySDKs()
        }
        return true
    }
    ```

*   **首屏渲染优化**: 
    *   **SwiftUI**: 在 SwiftUI 中，要特别注意主 `View` 的 `body` 属性的计算成本。避免在 `body` 中，进行任何耗时的计算。对于复杂的数据依赖，应该将其转移到 `ViewModel` 中，并使用 `@StateObject` / `@ObservedObject` 来驱动视图的更新。
    *   **UIKit**: 原则与 OC 项目相同，简化视图层级，优化 Auto Layout，避免离屏渲染等。

## 总结：Swift vs. OC 启动优化侧重点

| 优化方面 | Objective-C 项目 | Swift 项目 |
| :--- | :--- | :--- |
| **核心瓶颈** | **`+load` 方法** 和 **动态库数量** | **动态库数量** 和 **泛型特化** |
| **pre-main 优化** | 核心是**消灭 `+load`**，并减少动态库 | 核心是**减少动态库**，并警惕泛型膨胀 |
| **main 优化** | 异步化、懒加载 | 异步化、懒加载 (可利用现代并发) |

总的来说，由于 Swift 语言在设计上的静态化和懒加载特性，纯 Swift 项目在 `pre-main` 阶段，天然地就比同等规模的 OC 项目，具有更好的性能基础。其优化的重点，更多地在于**控制动态库的数量**，以及在 `main` 阶段，**有效地组织和异步化各种初始化任务**。