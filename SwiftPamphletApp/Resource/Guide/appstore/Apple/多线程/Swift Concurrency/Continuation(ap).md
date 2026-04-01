# 使用 Continuation 桥接旧世界

尽管 `async/await` 非常强大，但在实际项目中，我们仍然需要与大量基于“完成回调（Completion Handler）”模式的旧版 API 进行交互。为了不让我们的现代化 `async` 代码被这些旧 API 污染，Swift Concurrency 提供了一个至关重要的桥接工具：**Continuation**。

Continuation 允许你将一个基于回调的异步操作，包装成一个现代化的 `async` 函数。

## 1. 核心函数：`withCheckedThrowingContinuation`

这是最常用的一个函数。它会暂停当前的 `async` 任务，并提供一个 `continuation` 对象给你。你可以在这个闭包里执行任何旧版的异步 API。当旧 API 通过它的回调函数返回结果时，你再使用 `continuation` 对象来“唤醒”被暂停的任务，并将结果传递回去。

- **`continuation.resume(returning:)`**：当操作成功时，用这个方法返回结果。
- **`continuation.resume(throwing:)`**：当操作失败时，用这个方法抛出错误。

**关键规则：`resume` 方法必须且只能被调用一次。** 如果你忘记调用、或者调用了多次，程序会在运行时崩溃并给出明确的错误提示（这就是 `Checked` 的含义）。

### 示例：包装一个获取用户数据的旧 API

假设我们有这样一个旧的 API，它使用闭包来返回结果：

```swift
struct User {
    let name: String
}

enum FetchError: Error {
    case userNotFound
}

// 旧的、基于回调的 API
func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void) {
    // 模拟网络请求
    DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
        if id == "123" {
            completion(.success(User(name: "Taylor Swift")))
        } else {
            completion(.failure(FetchError.userNotFound))
        }
    }
}
```

现在，我们使用 `withCheckedThrowingContinuation` 将它包装成一个 `async` 函数：

```swift
// 新的、基于 async/await 的函数
func fetchUser(id: String) async throws -> User {
    // 暂停当前任务，进入闭包执行旧 API
    return try await withCheckedThrowingContinuation { continuation in
        // 调用旧的 API
        fetchUser(id: id) { result in
            // 在旧 API 的回调中，根据结果唤醒任务
            switch result {
            case .success(let user):
                // 成功，返回值
                continuation.resume(returning: user)
            case .failure(let error):
                // 失败，抛出错误
                continuation.resume(throwing: error)
            }
        }
    }
}

// 调用新的 async 函数
func loadUser() async {
    do {
        let user = try await fetchUser(id: "123")
        print("Fetched user: \(user.name)") // Fetched user: Taylor Swift
    } catch {
        print("Error: \(error)")
    }
}
```

通过这个包装，`loadUser` 函数内部的代码变得非常干净，完全摆脱了回调闭包的嵌套。

## 2. 其他类型的 Continuation

- **`withCheckedContinuation`**：用于包装那些不会失败、只返回单个值的旧 API。它只提供 `continuation.resume(returning:)` 方法。

- **`withUnsafeThrowingContinuation` / `withUnsafeContinuation`**：这些是“不安全”的版本。编译器不会检查 `resume` 是否被正确调用了一次。它们的性能稍高，因为省去了检查的开销，但如果你没有正确实现，可能会导致难以追踪的 bug（如任务永久挂起或崩溃）。**除非你处于对性能要求极高的场景，否则应始终优先使用 `Checked` 版本。**

## 3. 总结

Continuation 是新旧异步世界之间一座至关重要的桥梁。在任何一个从旧项目迁移到 Swift Concurrency 的过程中，你都会不可避免地大量使用它。

掌握 `withCheckedThrowingContinuation` 的用法，可以让你逐步地、平滑地将项目中的旧代码现代化，而无需一次性重写所有底层 API。
