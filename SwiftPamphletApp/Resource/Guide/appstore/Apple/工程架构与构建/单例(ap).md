# Swift 中的单例模式 (Singleton)

单例（Singleton）是一种常见的设计模式，它确保一个类在整个应用程序的生命周期中，只有一个实例存在，并为该实例提供一个全局唯一的访问点。在 iOS 和 macOS 开发中，许多系统框架都广泛使用了单例模式，例如 `UserDefaults.standard`, `FileManager.default`, `NotificationCenter.default` 等。

## 核心作用与目的

使用单例模式的主要目的在于：

1.  **保证唯一实例**: 对于某些需要协调整个应用行为的组件，如配置管理器、用户会话管理器或应用内购买处理器，确保只有一个实例可以避免状态冲突和不一致。
2.  **提供全局访问点**: 允许应用中的任何部分都可以方便地访问到这个唯一的实例，而无需通过复杂的依赖注入或属性传递。
3.  **资源管理**: 对于一些创建成本高或需要共享的资源（如数据库连接、网络会话），使用单例可以避免重复创建和销毁，节约系统资源。

## 在 Swift 中实现单例

在 Swift 中，实现一个线程安全的单例非常简单，这得益于 Swift 对静态属性的初始化机制。

```swift
import Foundation

// 定义一个单例类
class AppSettingsManager {
    
    // 1. 创建一个静态的、常量共享实例
    // Swift 保证 `static let` 的初始化是惰性的、线程安全的
    static let shared = AppSettingsManager()
    
    // 2. 将构造器私有化，防止外部创建新的实例
    private init() {
        // 在这里可以执行一些一次性的初始化设置
        print("AppSettingsManager instance created.")
    }
    
    // 示例属性和方法
    var theme: String = "Light"
    
    func saveTheme(_ newTheme: String) {
        self.theme = newTheme
        // ... 保存到持久化存储的逻辑 ...
    }
}

// 如何使用单例
func updateTheme() {
    // 通过全局访问点 `shared` 来访问唯一的实例
    AppSettingsManager.shared.saveTheme("Dark")
    
    let currentTheme = AppSettingsManager.shared.theme
    print("Current theme is: \(currentTheme)")
}
```

这个实现的关键点在于：
1.  **`static let shared = AppSettingsManager()`**: 我们声明了一个静态（`static`）的常量（`let`）`shared`，它持有了 `AppSettingsManager` 的一个实例。在 Swift 中，静态 `let` 属性的初始化是**惰性**的（只有在第一次访问时才会被创建）并且是**线程安全**的（系统会自动加锁，确保即使在多线程环境下也只会被创建一次）。这完美地满足了单例模式的要求。
2.  **`private init()`**: 我们将类的构造器（`init`）声明为私有（`private`）。这可以防止任何外部代码通过 `AppSettingsManager()` 的方式来创建新的实例，从而保证了 `shared` 是获取该类实例的唯一途径。

## 单例的优缺点

尽管单例模式非常方便，但它也常常被认为是一种“反模式”（anti-pattern），因为它可能带来一些问题。在使用之前，了解其优缺点至关重要。

### 优点

*   **简单易用**: 实现简单，访问方便。
*   **全局可访问**: 可以在代码的任何地方轻松获取实例。
*   **保证唯一性**: 对于需要全局协调的组件，这是一个很好的解决方案。

### 缺点

*   **全局状态 (Global State)**: 单例本质上是一个全局变量。全局状态会增加代码的复杂性，使得状态的变化难以追踪，容易产生意想不到的副作用。一个地方对单例的修改可能会影响到应用中完全不相关的另一部分。
*   **隐藏依赖 (Hidden Dependencies)**: 当一个类在内部直接调用 `MyManager.shared` 时，它就隐式地依赖于这个单例。这使得代码的依赖关系不明确，从外部看，你无法知道这个类到底需要哪些外部组件才能正常工作。
*   **难以测试 (Hard to Test)**: 依赖于单例的代码非常难以进行单元测试。因为你无法轻易地“替换”或“模拟”（mock）这个全局唯一的实例。测试用例之间可能会因为共享同一个单例实例而相互影响，导致测试结果不稳定。
*   **违反单一职责原则**: 单例类不仅要负责其自身的业务逻辑，还要负责管理自己的生命周期（保证唯一性），这在某种程度上违反了单一职责原则。

## 何时使用单例？

尽管有上述缺点，但在某些特定场景下，使用单例仍然是合理的。你应该在以下情况下考虑使用单例：

*   **真正的全局服务**: 当你需要一个真正意义上的、与平台或系统服务紧密相关的全局协调器时。苹果自己的框架就是最好的例子，如 `FileManager.default`, `URLSession.shared`。这些服务本身就是全局性的。
*   **日志记录器 (Logger)**: 在整个应用中使用同一个日志记录器实例来收集和写入日志。
*   **应用配置**: 管理那些在整个应用生命周期中都有效的、只读或很少改变的配置信息。

## 替代方案：依赖注入 (Dependency Injection)

对于大多数非全局性的服务，**依赖注入**是比单例更好的选择。依赖注入的核心思想是，一个对象不应该自己去创建或获取它所依赖的服务，而应该由外部（例如，它的创建者）将这些依赖“注入”给它。

```swift
// 服务
class UserManager {
    func fetchUser() -> String { "Alice" }
}

// 视图模型，通过构造器接收依赖
class MyViewModel {
    private let userManager: UserManager
    
    init(userManager: UserManager) {
        self.userManager = userManager
    }
    
    func loadUser() {
        let user = userManager.fetchUser()
        print(user)
    }
}

// 在应用组装层创建实例并注入
let userManager = UserManager()
let viewModel = MyViewModel(userManager: userManager)
```

**优势**: 
*   **依赖明确**: `MyViewModel` 的依赖关系非常清晰。
*   **易于测试**: 在测试时，你可以轻松地传入一个模拟的 `MockUserManager` 来代替真实的 `UserManager`。
*   **灵活性高**: 你可以为不同的场景提供不同的 `UserManager` 实现。

在 SwiftUI 中，依赖注入可以通过 `@EnvironmentObject` 或自定义的 `EnvironmentKey` 来优雅地实现。

## 总结

单例模式是一个简单但需要谨慎使用的工具。它为创建全局唯一实例提供了一个便捷的方案，但也可能引入全局状态、隐藏依赖和测试困难等问题。

*   **实现**: 使用 `static let shared` 和 `private init()`。
*   **适用场景**: 真正的全局服务，如日志、系统服务代理等。
*   **替代方案**: 对于大多数场景，优先考虑使用**依赖注入**，以构建更松耦合、更易于测试和维护的代码架构。

在决定使用单例之前，请务必仔细权衡其带来的便利性和潜在的长期维护成本。
