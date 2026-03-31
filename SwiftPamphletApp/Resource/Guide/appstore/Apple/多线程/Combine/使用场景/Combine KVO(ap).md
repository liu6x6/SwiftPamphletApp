# Combine 中的 KVO (键值观察) 替代方案

在 Objective-C 和早期的 Swift 开发中，KVO (Key-Value Observing) 是一种极其强大的机制，允许一个对象监听另一个对象某个属性的变化。但这套 C 语言风格的 API 一直以难用、容易引发内存泄漏崩溃（忘记 \`removeObserver\`）而臭名昭著。

Combine 提供了一种极其优雅、类型安全且内存安全的**现代版 KVO 替代方案**。

## 1. 原生 KVO 的 Combine 桥接：`.publisher(for:)`

Apple 为所有继承自 \`NSObject\` 的类提供了一个神奇的 \`publisher(for:)\` 方法。这意味着，所有 UIKit 控件或 AVFoundation 播放器中支持 KVO 的属性，现在都可以直接变成 Combine 的数据流。

### 实战：监听 ScrollView 的滚动偏移量

在过去，你要在 \`scrollViewDidScroll\` 代理里写代码；现在，你可以把它变成一条响应式的管道。

```swift
import UIKit
import Combine

class MyViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 核心：直接把 contentOffset 属性变成 Publisher！
        // .options: .initial 表示在订阅的一瞬间，先把当前的值发过来一次
        scrollView.publisher(for: \.contentOffset, options: [.initial, .new])
            // 可以随意加 Combine 操作符，比如过滤掉没有垂直滚动的废数据
            .filter { $0.y > 0 }
            .sink { [weak self] offset in
                print("当前滚动到了: \(offset.y)")
                
                // 比如实现导航栏渐变透明度效果
                let alpha = min(offset.y / 100.0, 1.0)
                self?.navigationController?.navigationBar.alpha = alpha
            }
            // 自动管理内存！当 ViewController 销毁时，监听自动解除，绝不崩溃！
            .store(in: &cancellables)
    }
}
```

### 实战：监听 AVPlayer 的播放状态

AVPlayer 出了名的难用，它的很多状态只能靠 KVO 获取。

```swift
// 监听视频是否已经准备好播放了
player.publisher(for: \.status)
    .sink { status in
        if status == .readyToPlay {
            print("视频缓冲完毕，可以播放")
        }
    }
    .store(in: &cancellables)
```

## 2. 纯 Swift 的替代方案：`@Published` 宏

如果你是在写纯 Swift 的业务模型（非继承自 `NSObject` 的类），你**不需要也不能**使用 KVO。

在这种场景下，Apple 给出的现代答案是 `ObservableObject` 协议配合 `@Published` 属性包装器。

```swift
// 1. 实现 ObservableObject 协议
class DownloadManager: ObservableObject {
    // 2. 给需要被观察的属性加上 @Published 宏
    @Published var progress: Double = 0.0
    
    func startDownload() {
        // ... 模拟下载 ...
        self.progress = 0.5 // 每次修改，系统会自动在幕后通过 objectWillChange 发送通知
    }
}

let manager = DownloadManager()

// 3. 在外部，你可以通过 $ 符号获取这个属性专属的 Publisher！
let cancellable = manager.$progress
    .sink { newProgress in
        print("UI 进度条更新为: \(newProgress)")
    }
```

## 总结

Combine 彻底杀死了古老、繁琐的 `addObserver / observeValue` 模式。
*   对于**系统级的 UIKit/Foundation 遗留对象**：使用 `object.publisher(for: \.keyPath)`。
*   对于**你自己的业务逻辑模型**：使用 `ObservableObject` 配合 `@Published`。
