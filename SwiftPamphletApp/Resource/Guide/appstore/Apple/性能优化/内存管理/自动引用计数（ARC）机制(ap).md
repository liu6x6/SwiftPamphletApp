# 自动引用计数（ARC）机制

自动引用计数（Automatic Reference Counting, ARC）是 Swift 语言中用于管理**引用类型**（主要是类实例）内存的核心机制。ARC 的目标是，在编译时自动地为你的代码插入正确的内存管理调用（`retain` 和 `release`），从而让你无需手动管理内存，同时又能获得接近手动管理的性能。

## 核心原理：引用计数

ARC 的工作原理非常直观：

1.  **跟踪引用**: ARC 会为每一个在堆上分配的类实例，维护一个“引用计数”（Reference Count）。这个计数，记录了当前有多少个“强引用”（strong reference）指向这个实例。

2.  **增加计数**: 每当一个强引用（例如，一个新的变量、常量或属性）指向一个类实例时，该实例的引用计数就会 `+1`。

3.  **减少计数**: 每当一个强引用被销毁（例如，持有它的变量被设置为 `nil`，或者变量超出了其作用域）时，该实例的引用计数就会 `-1`。

4.  **释放内存**: 一旦一个实例的引用计数变为 `0`，就意味着再也没有任何强引用指向它了。此时，ARC 会自动销毁该实例，并调用其 `deinit` 方法，然后释放其占用的内存。

```swift
class Person {
    let name: String
    init(name: String) {
        self.name = name
        print("\(name) 被初始化了")
    }
    deinit {
        print("\(name) 被释放了")
    }
}

var reference1: Person? = Person(name: "John") // 引用计数为 1
var reference2: Person? = reference1             // 引用计数为 2
var reference3: Person? = reference1             // 引用计数为 3

reference1 = nil // 引用计数为 2
reference2 = nil // 引用计数为 1
reference3 = nil // 引用计数为 0，此时 Person 实例被释放

// 控制台输出:
// John 被初始化了
// John 被释放了
```

## 强引用循环 (Strong Reference Cycles)

ARC 虽然很智能，但它无法解决一个经典的问题：**强引用循环**（也称为“循环引用”或“保留环” Retain Cycle）。

当两个或多个类实例，互相持有对方的强引用时，就会形成一个闭合的引用环。在这个环中，每个实例的引用计数，都至少为1（因为它被环中的另一个实例所持有）。这导致它们的引用计数永远无法降为零，即使已经没有任何外部引用指向它们，它们也无法被 ARC 释放，从而造成**内存泄漏**。

```swift
class Person {
    let name: String
    var apartment: Apartment?
    // ...
}

class Apartment {
    let unit: String
    var tenant: Person? // 默认是强引用
    // ...
}

var john: Person? = Person(name: "John")
var unit4A: Apartment? = Apartment(unit: "4A")

john!.apartment = unit4A // Person 持有 Apartment 的强引用
unit4A!.tenant = john   // Apartment 持有 Person 的强引用

// 此时，一个强引用循环形成

john = nil
unit4A = nil

// 即使 john 和 unit4A 被置为 nil，两个实例的引用计数仍然为 1，无法被释放
```

## 解决循环引用：`weak` 和 `unowned`

为了打破强引用循环，Swift 提供了两种非强引用类型：

### 1. `weak` (弱引用)

*   **特点**: `weak` 引用**不会**增加实例的引用计数。它所引用的实例，可以被 ARC 独立地释放。
*   **可选类型**: 因为弱引用的对象可能随时被销毁，所以 `weak` 引用必须被声明为**可选类型**（`Optional`）。当其引用的实例被释放后，ARC 会自动地将这个 `weak` 引用设置为 `nil`。这保证了你永远不会访问到一个无效的、悬垂的指针。
*   **适用场景**: 当两个实例的生命周期没有必然的关联，一方可以合法地先于另一方存在时，使用 `weak`。例如，在上面的例子中，一个“公寓”可以没有“租户”，所以 `tenant` 属性适合被声明为 `weak`。

```swift
class Apartment {
    let unit: String
    weak var tenant: Person?
    // ...
}
```

### 2. `unowned` (无主引用)

*   **特点**: `unowned` 引用也**不会**增加实例的引用计数。但它与 `weak` 的核心区别在于，它**假定**其引用的实例，在自己的整个生命周期中，都**永远不会**变为 `nil`。
*   **非可选类型**: 基于这个假定，`unowned` 引用总是非可选的。
*   **风险**: 如果你错误地使用了 `unowned`，并且在其引用的实例被销毁后，仍然试图访问它，你的程序将会**崩溃**。
*   **适用场景**: 当两个实例的生命周期是紧密绑定的，一个实例的存在，必然意味着另一个实例也存在时，使用 `unowned`。例如，一个“信用卡”（`CreditCard`）对象，它必然属于一个“客户”（`Customer`）。信用卡不可能在客户被销毁后，还独立存在。

```swift
class Customer {
    let name: String
    var card: CreditCard?
    // ...
}

class CreditCard {
    let number: UInt64
    unowned let customer: Customer // 信用卡必须有主人
    // ...
}
```

### 闭包中的循环引用

闭包也是引用类型。如果一个类的实例，持有一个闭包属性（例如，一个网络请求的回调），而这个闭包又在其内部，捕获了对该实例的强引用（`self`），也会形成循环引用。

**解决方法**: 使用**捕获列表（Capture List）**，在闭包的定义中，将对 `self` 的捕获，声明为 `[weak self]` 或 `[unowned self]`。

```swift
class MyViewController: UIViewController {
    var networkService = NetworkService()
    var data: [String] = []

    func fetchData() {
        networkService.fetchData { [weak self] result in
            // 使用 guard let 安全地解包 weak self
            guard let self = self else { return }
            
            // 在闭包内部安全地使用 self
            self.data = result
            self.tableView.reloadData()
        }
    }
}
```

## 总结

*   **ARC 是自动的，但不是万能的**: 它极大地简化了内存管理，但开发者仍需理解其原理，以应对循环引用的问题。
*   **强引用是默认的**: 所有的属性、变量和常量，默认都是强引用。
*   **循环引用是内存泄漏的主要原因**: 当两个对象互相强引用对方时，就会发生内存泄漏。
*   **`weak` 和 `unowned` 是解药**: 
    *   当两个对象的生命周期不完全相同时，使用 `weak`。
    *   当一个对象的生命周期，完全依赖于另一个对象时，使用 `unowned`。
    *   在闭包中，使用 `[weak self]` 来避免与 `self` 的循环引用。

正确地管理引用关系，是编写健壮、无内存泄漏的 Swift 应用的关键。