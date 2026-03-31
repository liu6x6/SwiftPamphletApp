# SwiftUI 中的进度指示器 (ProgressView)

`ProgressView` 是 SwiftUI 中用于向用户展示一个正在进行的任务进度的标准视图。它有两种主要形式：

1.  **不确定性进度 (Indeterminate)**: 当任务的总时长未知时使用。它通常表现为一个持续旋转的加载指示器（spinner），告诉用户“正在处理中”。
2.  **确定性进度 (Determinate)**: 当任务的进度可以被量化时使用（例如，文件下载、数据处理）。它通常表现为一个会逐渐被填满的进度条。

## 不确定性进度 (Indeterminate)

这是 `ProgressView` 最简单的用法。你只需要创建一个不带任何参数的 `ProgressView` 实例，它就会显示一个旋转的加载动画。

```swift
import SwiftUI

struct IndeterminateProgressExample: View {
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 30) {
            if isLoading {
                // 显示一个旋转的加载指示器
                ProgressView("正在加载数据...")
                    .progressViewStyle(.circular) // 明确指定为圆形样式
            } else {
                Text("加载完成！")
            }
            
            Button(isLoading ? "停止加载" : "开始加载") {
                isLoading.toggle()
            }
        }
    }
}

#Preview {
    IndeterminateProgressExample()
}
```

在这个例子中：
*   当 `isLoading` 为 `true` 时，我们显示一个 `ProgressView`。
*   `ProgressView("正在加载数据...")` 会在旋转指示器的旁边或下方（取决于平台和上下文）显示一段描述性文本。
*   `.progressViewStyle(.circular)` 明确指定了使用圆形旋转样式，这是不确定性进度的默认样式。

## 确定性进度 (Determinate)

要创建一个显示具体进度的 `ProgressView`，你需要提供两个关键参数：

1.  **`value`**: 一个表示当前进度的 `Double` 值，范围通常在 0.0 到 1.0 之间。
2.  **`total`** (可选): 一个表示总进度的 `Double` 值，默认为 1.0。

```swift
struct DeterminateProgressExample: View {
    @State private var downloadProgress: Double = 0.0

    var body: some View {
        VStack(spacing: 20) {
            Text("下载进度: \(Int(downloadProgress * 100))%")
            
            // 创建一个确定性进度条
            ProgressView(value: downloadProgress, total: 1.0)
                .progressViewStyle(.linear) // 明确指定为线性样式
            
            Button("模拟下载") {
                // 使用 Timer 模拟进度的增加
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                    if self.downloadProgress < 1.0 {
                        self.downloadProgress += 0.01
                    } else {
                        timer.invalidate()
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    DeterminateProgressExample()
}
```

在这个例子中：
*   `downloadProgress` 状态变量存储了当前的下载进度。
*   `ProgressView(value: downloadProgress, total: 1.0)` 创建了一个进度条，其填充程度与 `downloadProgress` 的值同步。
*   `.progressViewStyle(.linear)` 明确指定了使用水平进度条样式，这是确定性进度的默认样式。

## 自定义 `ProgressView` 的样式

与许多其他 SwiftUI 控件一样，你可以通过 `.progressViewStyle()` 修饰符来改变 `ProgressView` 的外观，甚至创建自己的样式。

### 内置样式

*   `.automatic`: 默认样式。
*   `.circular`: 圆形旋转指示器样式。
*   `.linear`: 水平进度条样式。

### 自定义 `ProgressViewStyle`

通过创建一个遵循 `ProgressViewStyle` 协议的结构体，你可以完全控制 `ProgressView` 的渲染方式。你需要实现 `makeBody(configuration:)` 方法，该方法提供了一个 `configuration` 对象，其中包含：

*   `configuration.label`: 进度视图的标签。
*   `configuration.fractionCompleted`: 一个表示当前进度的 `Double?` 值（从 0.0 到 1.0）。如果不确定性进度，则为 `nil`。

#### 示例：创建一个垂直的胶囊进度条

```swift
struct CapsuleProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        let fraction = configuration.fractionCompleted ?? 0
        
        VStack {
            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                
                Capsule()
                    .fill(Color.blue)
                    .frame(height: 200 * fraction)
            }
            .frame(width: 30, height: 200)
            
            configuration.label
        }
    }
}

struct CustomProgressViewStyleExample: View {
    @State private var progress = 0.65
    
    var body: some View {
        ProgressView("任务进度", value: progress)
            .progressViewStyle(CapsuleProgressViewStyle())
    }
}

#Preview {
    CustomProgressViewStyleExample()
}
```

在这个例子中，我们创建了一个 `CapsuleProgressViewStyle`，它使用两个 `Capsule` 形状来构建一个垂直的进度条。蓝色胶囊的高度由 `configuration.fractionCompleted` 动态决定。

## 改变 `ProgressView` 的颜色

对于系统提供的样式，你可以使用 `.tint()` 修饰符来改变进度条或旋转指示器的颜色。

```swift
VStack {
    ProgressView()
        .tint(.purple)
    
    ProgressView(value: 0.7)
        .tint(.orange)
}
```

## 总结

`ProgressView` 是向用户传达后台任务状态的重要视觉工具。

*   **不确定性**: 当任务时长未知时，使用不带参数的 `ProgressView()` 来显示一个旋转指示器。
*   **确定性**: 当任务进度可量化时，使用 `ProgressView(value:total:)` 来显示一个进度条。
*   **样式**: 通过 `.progressViewStyle()` 可以切换为圆形或线性样式，或应用完全自定义的样式。
*   **颜色**: 使用 `.tint()` 是改变默认样式颜色的最简单方法。

在执行任何耗时超过一两秒的操作时，都应该考虑使用 `ProgressView` 来提供清晰的反馈，这可以显著提升应用的用户体验，避免让用户感觉应用“卡住”了。
