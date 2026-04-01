# Swift 并发基石：async / await

`async` 和 `await` 是 Swift Concurrency 模型最核心、最基础的两个关键字。它们彻底改变了我们编写和阅读异步代码的方式，将曾经令人头痛的“回调地狱”变成了清晰、线性的代码流。

## 1. `async`：标记一个异步函数

`async` 关键字用于标记一个函数、方法或闭包是“异步”的。这意味着：

1.  **可以被挂起**：这个函数内部可以包含 `await` 表达式。当执行到 `await` 时，函数可能会被“挂起（suspend）”，暂时让出当前线程的控制权，以便 CPU 可以去执行其他任务。
2.  **不会立即返回结果**：一个 `async` 函数的调用者不会立刻得到最终结果，而是得到一个“承诺（Promise）”，表示未来某个时刻会有一个结果（或错误）产生。

```swift
// 这是一个同步函数，它会阻塞线程直到图片下载完成
func fetchImageBlocking(from url: URL) -> UIImage? {
    // ... 执行耗时的网络请求 ...
    return UIImage(data: data)
}

// 这是一个异步函数，它不会阻塞线程
// 它在函数签名中用 async 标记
func fetchImage(from url: URL) async throws -> UIImage? {
    // 使用 URLSession 的新 async API
    let (data, _) = try await URLSession.shared.data(from: url)
    return UIImage(data: data)
}
```

## 2. `await`：等待一个异步调用的结果

`await` 关键字用在调用 `async` 函数的地方。它告诉编译器：“这里的代码需要等待一个异步操作完成，请在等待期间将我挂起，并在操作完成后从这里恢复执行。”

### 挂起 vs. 阻塞 (Suspend vs. Block)

这是理解 `async/await` 的关键所在：

- **阻塞 (Blocking)**：一个被阻塞的线程会完全停滞，无法执行任何其他代码。如果主线程被阻塞，App 界面会卡死。这是旧的同步 I/O 的工作方式。
- **挂起 (Suspending)**：一个被挂起的任务会**释放**它所在的线程。Swift Concurrency 的运行时系统会把这个线程交给其他准备就绪的任务去使用。当 `await` 的操作（如网络请求）完成后，运行时系统会找到一个可用的线程，让被挂起的任务从 `await` 的下一行代码继续执行。**整个过程 App 保持流畅响应。**

```swift
struct ProfileView: View {
    @State private var userAvatar: UIImage?

    var body: some View {
        Image(uiImage: userAvatar ?? UIImage(systemName: "person.circle")!)
            .onAppear {
                // 启动一个异步任务来加载头像
                Task {
                    do {
                        let avatarURL = URL(string: "https://example.com/avatar.jpg")!
                        // 调用异步函数，并使用 await 等待结果
                        // 在等待期间，UI 线程可以自由地响应用户交互
                        self.userAvatar = try await fetchImage(from: avatarURL)
                    } catch {
                        print("Failed to fetch avatar: \(error)")
                    }
                }
            }
    }
}
```

## 3. `async let`：并行执行多个异步任务

如果你需要同时发起多个独立的异步操作，然后等待它们全部完成，使用 `async let` 是最高效的方式。它会立即开始执行所有异步调用，让你并行地利用等待时间。

```swift
func loadUserProfile() async throws {
    print("Start loading profile...")
    
    // 使用 async let 并行地开始下载用户信息和好友列表
    async let user = fetchUser()
    async let friends = fetchFriends()
    async let posts = fetchPosts()

    // 当你需要结果时，使用 await 来等待
    // Swift 会在这里等待三个网络请求全部完成
    let profileData = try await (user: user, friends: friends, posts: posts)

    // 到达这里时，所有数据都已准备就绪
    print("Welcome, \(profileData.user.name)!")
    print("You have \(profileData.friends.count) friends.")
}
```

在这个例子中，三个 `fetch` 函数会几乎同时开始执行。程序会等到 `await` 那一行，收集所有结果，然后继续。这比一个一个地 `await` 调用它们要快得多。

## 总结

- **`async`** 声明了一个可以被挂起的异步函数。
- **`await`** 暂停当前任务的执行，等待一个 `async` 函数返回结果，但不会阻塞线程。
- **`async let`** 允许你创建并行的子任务，以最高效率执行多个独立的异步操作。

`async/await` 是 Swift Concurrency 的语法核心，它让复杂的异步逻辑变得像同步代码一样直观和易于维护。
