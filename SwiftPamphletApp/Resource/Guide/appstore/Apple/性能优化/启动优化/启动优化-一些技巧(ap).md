# 启动优化：一些实用技巧

除了宏观的架构调整和编译选项优化，还有许多在日常编码中可以实践的、具体的“小技巧”，它们同样能够对 App 的启动性能，产生积极的影响。

## 1. 优化 `main` 函数之前的阶段 (pre-main)

pre-main 阶段的耗时，主要来自于动态链接器（`dyld`）加载和链接动态库的工作。因此，优化的核心是**减少 `dyld` 的工作量**。

*   **减少动态库数量**: 这是最核心的优化。将非必要的动态库，改为静态链接。对于大型组件化项目，可以开启“可合并库”（Mergeable Libraries）功能，将多个动态库，在链接时自动合并成一个。

*   **减少 `+load` 方法**: 在 Objective-C 中，`+load` 方法会在类被加载到内存时，自动调用。`dyld` 在加载阶段，需要处理这些 `+load` 方法，如果数量过多，会拖慢启动速度。应该将 `+load` 中的代码，尽可能地转移到 `+initialize` 方法中。`+initialize` 是在类第一次收到消息时，才会被“懒加载”式地调用。

*   **减少静态初始化器**: 在 Swift 和 C++ 中，全局变量和静态变量的初始化器，也会在 `dyld` 加载阶段执行。应该避免在这些初始化器中，进行复杂的、耗时的操作。

## 2. 优化 `main` 函数之后的阶段 (main)

main 阶段的耗时，主要来自于 `application(_:didFinishLaunchingWithOptions:)` 方法以及首屏渲染所需的时间。优化的核心是**“延迟”和“异步”**。

### 2.1 `didFinishLaunchingWithOptions` 的瘦身

这个方法，是 App 启动后，我们能控制的第一个代码执行点。它必须在系统规定的时间内执行完毕，否则 App 会被系统强杀。因此，这个方法必须极其轻量。

*   **原则**: 只做与**首屏渲染直接相关**的、**必须同步**完成的初始化工作。

*   **反模式**: 
    *   ❌ 在这里同步地进行网络请求。
    *   ❌ 在这里同步地进行复杂的文件读写或数据库初始化。
    *   ❌ 在这里初始化所有与首屏无关的第三方 SDK。

*   **优化策略**:
    1.  **延迟加载 (Lazy Initialization)**: 将那些不是立即需要的对象（特别是单例），都改为懒加载模式。只有在它们第一次被访问时，才进行真正的初始化。
        ```swift
        // 使用 lazy var 来延迟初始化
        lazy var locationManager: CLLocationManager = {
            let manager = CLLocationManager()
            // ... 进行复杂的配置 ...
            return manager
        }()
        ```

    2.  **异步初始化**: 将所有非首屏必须的初始化工作（如第三方 SDK 的初始化、数据预加载、日志系统配置等），都异步地派发到后台线程去执行。
        ```swift
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            // 1. 只做必要的、同步的 UI 设置
            self.window = UIWindow(frame: UIScreen.main.bounds)
            self.window?.rootViewController = MainViewController()
            self.window?.makeKeyAndVisible()

            // 2. 将所有其他工作，都派发到后台队列
            DispatchQueue.global(qos: .background).async {
                self.setupThirdPartySDKs()
                self.preloadData()
                self.setupLogger()
            }

            return true
        }
        ```

### 2.2 首屏渲染优化

*   **简化首屏 UI**: 尽可能地简化首屏的视图层级和布局复杂度。
*   **避免在 `viewDidLoad` 或 `viewDidAppear` 中进行耗时操作**: 与 `didFinishLaunchingWithOptions` 的优化原则一样。
*   **使用占位符 (Placeholder)**: 对于首屏需要显示的网络数据，应该先显示一个“骨架屏”（Skeleton View）或占位图，然后再异步地去请求数据。这可以极大地提升用户的“感知启动速度”。

## 3. 使用 Order File

通过使用 Order File，将所有启动阶段需要用到的函数，在物理上排列在一起，可以极大地减少“缺页中断”（Page Fault），提升 I/O 效率，从而加快启动速度。

（更多详情请参阅 `包体积-链接器优化(ap).md`）

## 总结

启动优化，是一个需要从 `pre-main` 和 `main` 两个阶段，进行系统性治理的工程。

*   **`pre-main` 阶段**: 核心是**减少动态库的数量**。
*   **`main` 阶段**: 核心是**延迟（Lazy）**和**异步（Async）**。

通过将所有非必要的、耗时的操作，都从主线程的启动路径中移除，我们可以最大限度地缩短 App 的启动时间，为用户提供“秒开”的极致体验。