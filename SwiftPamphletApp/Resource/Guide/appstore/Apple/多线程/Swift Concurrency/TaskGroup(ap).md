# 使用 TaskGroup 处理动态并发任务

当我们需要并行执行多个异步任务时，`async let` 是一个很好的选择。但它有一个限制：必须在编译时就知道要执行多少个任务。

如果我们需要在一个循环中，或者根据一个动态的数组来创建不确定数量的并行任务，那么 **`TaskGroup`** 就是我们需要的工具。

## 1. 什么是 TaskGroup？

`TaskGroup` 提供了一种动态创建一组子任务（child tasks）并在它们完成时收集结果的机制。它属于结构化并发的一部分，拥有和 `async let` 类似的行为：

- **生命周期绑定**：任务组的生命周期不会超过创建它的作用域。
- **自动取消**：如果任务组本身或创建它的父任务被取消，组内的所有任务都会被自动取消。
- **错误传递**：如果组内的任何一个子任务抛出错误，整个任务组可以被立即中断，并将错误向上传递。

## 2. 如何使用 `withThrowingTaskGroup`

最常见的用法是 `withThrowingTaskGroup`，它允许组内的子任务抛出错误。

它的基本工作流程如下：

1.  调用 `withThrowingTaskGroup` 创建一个任务组作用域。
2.  在闭包内部，你会得到一个 `group` 对象。
3.  使用 `group.addTask()` 来向组内动态添加新的子任务。这些任务会立即开始并行执行。
4.  使用 `for await ... in group` 来遍历并等待组内所有任务的完成。每当一个子任务完成时，它的结果就会在这个循环中出现。
5.  当 `withThrowingTaskGroup` 的闭包结束时，Swift 会隐式地等待所有被添加到组里的任务都执行完毕。

### 示例：并行下载一组图片

假设我们需要从一个 URL 数组中下载所有的图片。

```swift
import SwiftUI

func downloadImage(from url: URL) async throws -> UIImage {
    let (data, _) = try await URLSession.shared.data(from: url)
    guard let image = UIImage(data: data) else {
        throw URLError(.badServerResponse) // Or a custom error
    }
    return image
}

// 使用 TaskGroup 并行下载所有图片
func downloadAllImages(from urls: [URL]) async throws -> [UIImage] {
    var downloadedImages: [UIImage] = []
    
    // 1. 创建一个可以抛出错误的 TaskGroup
    try await withThrowingTaskGroup(of: UIImage.self) { group in
        // 2. 遍历 URL 数组，为每个 URL 添加一个下载任务
        for url in urls {
            group.addTask {
                // 在子任务中执行异步下载
                return try await downloadImage(from: url)
            }
        }

        // 3. 遍历 group，收集已完成任务的结果
        // 这个循环会一直等待，直到所有添加到 group 的任务都返回结果
        for try await image in group {
            downloadedImages.append(image)
        }
    }
    
    // 4. 当 withThrowingTaskGroup 闭包结束时，所有图片都已下载完成
    return downloadedImages
}
```

## 3. 错误处理和取消

`TaskGroup` 在错误处理上非常强大。

- **隐式取消**：在 `withThrowingTaskGroup` 中，只要有一个子任务抛出了错误，`group` 会立即取消所有其他正在运行的子任务。这可以避免不必要的计算资源浪费。然后，错误会从 `for try await` 循环中被抛出。

- **显式取消**：你也可以手动调用 `group.cancelAll()` 来取消所有子任务。

## 4. `withTaskGroup`

如果你确定组内的任务不会抛出错误，可以使用 `withTaskGroup`。它的用法与 `withThrowingTaskGroup` 完全相同，只是 `addTask` 的闭包不能是 `throws` 的，并且遍历 `group` 时使用 `for await` 而不是 `for try await`。

## TaskGroup vs. async let

| 特性 | `async let` | `TaskGroup` |
| :--- | :--- | :--- |
| **任务数量** | 编译时固定 | 运行时动态 |
| **适用场景** | 同时获取少量、固定的异构数据（如用户信息、设置、好友列表） | 遍历一个集合，对每个元素执行相同的并行操作（如批量下载、批量处理） |
| **语法** | 更简洁 | 稍微复杂，但更灵活 |

总而言之，`TaskGroup` 是 Swift Concurrency 中处理大规模、动态并行任务的瑞士军刀，它在提供了强大灵活性的同时，也通过结构化并发保证了代码的安全性和可维护性。
