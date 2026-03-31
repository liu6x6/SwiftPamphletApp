# SwiftUI 动画实例集锦

理论是基础，但通过实例来学习动画是掌握其精髓的最佳方式。本篇将展示一系列常见且实用的 SwiftUI 动画例子，涵盖从基础到高级的多种技巧。

## 1. 加载动画 (Loading Spinner)

一个简单的、无限旋转的加载指示器，使用 `.repeatForever`。

```swift
import SwiftUI

struct LoadingSpinner: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color.blue, lineWidth: 5)
            .frame(width: 50, height: 50)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(
                    .linear(duration: 1).repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

#Preview {
    LoadingSpinner()
}
```

**技巧**: 我们通过 `.trim` 来裁剪 `Circle`，只显示其中的一部分，然后通过无限旋转 `.rotationEffect` 来创建出经典的加载动画效果。

## 2. 心跳动画 (Heartbeat)

一个模拟心跳的、重复缩放的动画。

```swift
struct HeartbeatAnimation: View {
    @State private var isBeating = false

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 100))
            .foregroundColor(.red)
            .scaleEffect(isBeating ? 1.2 : 1.0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                ) {
                    isBeating = true
                }
            }
    }
}

#Preview {
    HeartbeatAnimation()
}
```

**技巧**: 使用 `.repeatForever(autoreverses: true)` 可以让动画在放大和缩小之间来回播放，完美地模拟了心跳的节奏。

## 3. 波浪动画 (Wave Animation)

模拟文字像波浪一样依次起伏的动画。

```swift
struct WaveTextAnimation: View {
    let text = "Hello, SwiftUI!"
    @State private var waveAmount = 0.0

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .offset(y: CGFloat(sin(waveAmount + Double(index) / 2.0)) * 10)
            }
        }
        .onAppear {
            withAnimation(
                .linear(duration: 2).repeatForever(autoreverses: false)
            ) {
                waveAmount = .pi * 2
            }
        }
    }
}

#Preview {
    WaveTextAnimation()
}
```

**技巧**: 我们将字符串分解为单个字符，并为每个字符应用一个基于其索引和 `sin` 函数的垂直偏移。通过动画地改变 `sin` 函数的输入（`waveAmount`），我们创建了平滑的波浪效果。

## 4. 视图过渡 (`.transition`)

当一个视图被添加或移除时，使用 `.transition` 来定义其出现和消失的动画。

```swift
struct TransitionExample: View {
    @State private var showDetails = false

    var body: some View {
        VStack {
            Button("显示/隐藏详情") {
                withAnimation(.spring()) {
                    showDetails.toggle()
                }
            }
            
            if showDetails {
                Text("这是一些详细信息。")
                    .padding()
                    .background(Color.yellow.opacity(0.5))
                    .cornerRadius(10)
                    // 定义出现和消失的过渡动画
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

#Preview {
    TransitionExample()
}
```

**技巧**: `.transition` 只在视图的“存在”与“不存在”状态切换时生效。`.combined(with:)` 允许你将多个过渡效果（如移动和透明度）组合在一起。

## 5. 共享元素过渡 (`MatchedGeometryEffect`)

在两个不同的视图之间平滑地移动和变形，创建“魔法移动”效果。

```swift
struct MagicMoveExample: View {
    @Namespace private var ns
    @State private var showDetail = false

    var body: some View {
        VStack {
            if showDetail {
                // 详情视图
                Circle()
                    .fill(Color.blue)
                    .matchedGeometryEffect(id: "circle", in: ns)
                    .frame(width: 200, height: 200)
            } else {
                // 列表视图
                Circle()
                    .fill(Color.red)
                    .matchedGeometryEffect(id: "circle", in: ns)
                    .frame(width: 100, height: 100)
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showDetail.toggle()
            }
        }
    }
}

#Preview {
    MagicMoveExample()
}
```

**技巧**: 关键在于两个 `Circle` 视图共享了相同的 `id` (`"circle"`) 和 `namespace` (`ns`)。当 `showDetail` 状态改变时，SwiftUI 会自动在这两个视图的几何属性（位置、尺寸）之间创建平滑的过渡动画。

## 总结

这些例子只是 SwiftUI 动画能力的冰山一角。通过组合不同的动画类型、修饰符和高级工具，你可以创造出无限的可能性。

学习动画的关键在于：
1.  **分解问题**: 将复杂的动画分解为一系列简单的状态变化。
2.  **选择工具**: 根据场景选择最合适的工具（`.animation`, `withAnimation`, `.transition`, `.matchedGeometryEffect` 等）。
3.  **不断实验**: 调整动画的参数（`duration`, `delay`, `spring` 物理属性等），直到找到最自然、最令人愉悦的感觉。

动画是提升应用品质和用户体验的点睛之笔。多看、多学、多实践，你也能成为 SwiftUI 动画大师。
