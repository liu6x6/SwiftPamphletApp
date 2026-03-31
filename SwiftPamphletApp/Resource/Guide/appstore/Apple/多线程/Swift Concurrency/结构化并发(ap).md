# 结构化并发 (Structured Concurrency)

在掌握了 \`async/await\` 之后，你只能做到**“排队等”**（串行异步，也就是等完 A 再等 B）。
但如果我想**同时**下载三张图片，然后等它们**全都**下载完之后，再把它们拼到一起呢？这就涉及到了并发执行。

Swift 提供了**结构化并发**，它是用来极其安全、可控地管理多个并行任务的机制。

## 1. 什么是“结构化”？

在传统的 \`DispatchQueue.global().async\` 中，你把一个任务扔进后台，它就像断了线的风筝（Fire and Forget）。如果用户中途退出了页面，那个后台下载任务还在偷偷浪费流量，很难被追踪和取消。这就是“非结构化”。

**结构化并发**强制要求任务必须有清晰的父子层级树状结构。
*   **同生共死**：如果父任务报错失败或被取消了，框架会自动、递归地取消它底下所有的子任务！
*   **隐式等待**：父任务必须等待所有子任务全部完成，它自己才能结束。

## 2. 方式一：async let (固定数量的并发)

当你明确知道要并发执行几个独立任务时，\`async let\` 是最简单优雅的语法。

```swift
func fetchUserProfileAndPosts() async throws -> (Profile, [Post]) {
    // 1. 遇到 async let 时，任务会立刻在这个函数的子层级被【并发】扔出去执行，
    // 代码绝对不会在这里卡住，而是瞬间走到下一行！
    async let profileTask = fetchProfile()
    async let postsTask = fetchPosts()
    
    // 2. 只有当你真正需要用到这两个任务的结果时，才使用 await 强行等待它们。
    // 这里会一直等到 profileTask 和 postsTask 【都】完成为止。
    let profile = try await profileTask
    let posts = try await postsTask
    
    // 如果 fetchProfile() 报错崩溃了，系统会自动取消 fetchPosts() 的网络请求！
    return (profile, posts)
}
```

## 3. 方式二：TaskGroup (动态数量的并发)

如果并发任务的数量是不确定的（比如你要根据一个数组的长度，并发下载 100 张图片），你就不能写 100 行 \`async let\` 了。这时必须使用 **\`TaskGroup\`**。

```swift
func downloadAllImages(urls: [URL]) async throws -> [UIImage] {
    // 开启一个可以返回 UIImage 的任务组
    // withThrowingTaskGroup 表示组里如果有任何一个任务报错，整个组直接抛出错误并取消其他任务
    return try await withThrowingTaskGroup(of: UIImage.self) { group in
        var finalImages: [UIImage] = []
        
        // 1. 把所有下载任务统统塞进组里，它们会立刻并发执行
        for url in urls {
            group.addTask {
                return try await downloadImage(from: url) // 你定义的 async 下载方法
            }
        }
        
        // 2. 在一个 for await 循环中，挨个接收完成的结果。
        // 注意：先下载完的图片会先从组里吐出来，不一定保证和塞进去的顺序一样！
        for try await image in group {
            finalImages.append(image)
        }
        
        return finalImages
    }
}
```

## 4. 取消任务 (Cancellation)

结构化并发的灵魂就在于取消。当你在 SwiftUI 的 \`.task { }\` 修饰符里发起网络请求时，如果用户滑走了这个视图，SwiftUI 会**自动取消**这个 Task！

但是在你手写的长耗时（如一个庞大的 for 循环计算）异步代码内部，你需要**主动配合**系统的取消机制：

```swift
func veryHeavyComputation() async throws {
    for i in 0..<10_000_000 {
        // 核心：在耗时循环的每次迭代前，检查一下父任务是不是被取消了。
        // 如果被取消了，直接抛出 CancellationError 中断计算，节约 CPU 资源！
        try Task.checkCancellation()
        
        // 执行复杂的计算...
    }
}
```
