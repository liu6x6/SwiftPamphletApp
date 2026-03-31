# async / await：告别回调地狱

\`async\` 和 \`await\` 是 Swift Concurrency 最基础、也是你日常开发中使用最频繁的两个关键字。它们彻底改变了 Swift 中编写异步函数的范式。

## 1. 传统的闭包回调之痛 (Callback Hell)

在以前，假设我们要实现一个完整的业务流：1. 下载图片数据 -> 2. 解码成图片 -> 3. 对图片进行裁剪缩放。
因为每一步都是耗时的，我们必须用闭包：

```swift
// 旧时代的写法
func processImage(url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
    downloadData(url: url) { dataResult in
        switch dataResult {
        case .success(let data):
            decodeImage(data: data) { imageResult in
                switch imageResult {
                case .success(let image):
                    resizeImage(image: image) { finalResult in
                        // 灾难般的三层缩进嵌套，且极易漏写 completion 回调导致逻辑死锁
                        completion(finalResult)
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .failure(let error):
            completion(.failure(error))
        }
    }
}
```

## 2. 现代的 async / await 写法

使用了新特性后，同样逻辑的代码变得和同步代码一样清晰：

```swift
// 1. 在函数名后加上 async 关键字，声明这是一个异步函数
// 2. 如果它可能失败，依然加上 throws
func processImage(url: URL) async throws -> UIImage {
    
    // 3. 在调用异步函数前，必须加上 await 关键字
    // 这意味着：执行到这里时，当前函数会“暂停”，交出线程控制权去干别的活。
    // 直到下载完成，代码才会继续往下走。
    let data = try await downloadData(url: url)
    
    // 拿着第一步的结果，等待第二步
    let image = try await decodeImage(data: data)
    
    // 等待第三步
    let finalImage = try await resizeImage(image: image)
    
    // 直接返回最终结果！
    return finalImage
}
```

## 3. 关键字的含义与规则

### \`async\` (异步的)
*   **作用**：用来标记一个函数、属性或闭包是**可以被挂起（暂停）**的。
*   **规则**：\`async\` 必须写在参数列表 \`()\` 之后，返回箭头 \`->\` 之前。如果还有 \`throws\`，它必须写在 \`throws\` 前面（即 \`async throws\`）。

### \`await\` (等待)
*   **作用**：用来标记潜在的**悬挂点 (Suspension Point)**。
*   **核心原理**：当你写下 \`await\` 时，你是在告诉系统：“这个操作可能需要很久（比如等网速），我愿意把当前占用的 CPU 线程让出来，你拿去渲染 UI 或者处理其他人的请求。等网络数据真回来了，你再把我叫醒，我接着往下跑。”
*   **规则**：你**只能**在一个被 \`async\` 标记的环境（比如 \`async\` 函数内部，或者 \`Task\` 闭包中）去调用带有 \`await\` 的代码。

## 4. 常见的系统 async API

Apple 在 iOS 15 / macOS 12 中，为几乎所有旧版的闭包系统 API 都免费提供了一套并行的 \`async\` 变体：

```swift
// 网络请求
let (data, response) = try await URLSession.shared.data(from: url)

// 睡眠 (替代 Thread.sleep)
try await Task.sleep(nanoseconds: 1_000_000_000) // 睡 1 秒

// 照片库请求权限
let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
```

**总结**：只要你看到系统 API 的末尾需要传入一个 \`completionHandler\`，请立刻停下，去寻找它是否有 \`async\` 版本，然后拥抱 \`await\` 的线性之美。
