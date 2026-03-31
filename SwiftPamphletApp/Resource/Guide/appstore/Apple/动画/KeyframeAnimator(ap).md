# SwiftUI 动画：KeyframeAnimator (iOS 17+)

`KeyframeAnimator`（关键帧动画器）是苹果在 WWDC 2023 (iOS 17) 中引入的一个极其强大的动画工具。它允许开发者定义一系列的“关键帧”（Keyframes），来精确地、分步骤地控制一个或多个属性的动画过程。这使得创建复杂的、非线性的、多阶段的动画变得前所未有的简单和声明式。

在此之前，要实现类似的效果，开发者通常需要依赖多个嵌套的 `withAnimation` 闭包、复杂的 `DispatchQueue.main.asyncAfter` 延迟调用链，或者自定义 `Animatable` 类型，代码非常繁琐且难以维护。

## 核心概念

`KeyframeAnimator` 的工作方式类似于专业的动画软件：

1.  **定义动画值**: 你首先定义一个结构体，其中包含了所有你希望进行动画的属性（例如 `scale`, `rotation`, `offset` 等）。
2.  **定义关键帧**: 你创建一个 `KeyframeTimeline`，并在其中为你定义的每个动画值，设置一系列的关键帧。每个关键帧都指定了在动画的某个时间点，该属性应该达到的目标值，以及达到该目标值所使用的动画曲线。
3.  **应用动画**: `KeyframeAnimator` 视图会根据你定义的关键帧时间线，自动计算并更新动画值。你可以在其 `content` 闭包中，将这些动态的值应用到你的视图上。

## 基本用法

让我们创建一个让一个图标“跳动”一下的动画效果。

```swift
import SwiftUI

struct KeyframeAnimatorExample: View {
    // 1. 定义动画值的结构体
    struct AnimationValues {
        var scale: Double = 1.0
        var verticalOffset: Double = 0.0
    }
    
    @State private var startAnimation = false

    var body: some View {
        VStack {
            KeyframeAnimator(
                initialValue: AnimationValues(), // 初始值
                trigger: startAnimation // 动画的触发器
            ) { content, values in
                // 3. 将动画值应用到视图上
                Image(systemName: "heart.fill")
                    .font(.largeTitle)
                    .scaleEffect(values.scale)
                    .offset(y: values.verticalOffset)
            } keyframes: { _ in
                // 2. 定义关键帧时间线
                KeyframeTrack(\.scale) {
                    CubicKeyframe(1.2, duration: 0.2) // 0.2秒内放大到1.2倍
                    CubicKeyframe(1.0, duration: 0.2) // 0.2秒内缩回1.0倍
                }
                
                KeyframeTrack(\.verticalOffset) {
                    CubicKeyframe(-20, duration: 0.2) // 0.2秒内向上移动20
                    CubicKeyframe(0, duration: 0.2)   // 0.2秒内移回原位
                }
            }
            
            Button("跳动") {
                startAnimation.toggle()
            }
        }
    }
}

#Preview {
    KeyframeAnimatorExample()
}
```

在这个例子中：
1.  我们定义了 `AnimationValues` 来统一管理 `scale` 和 `verticalOffset` 两个动画属性。
2.  在 `keyframes` 闭包中，我们为 `\.scale` 和 `\.verticalOffset` 两个属性分别创建了一个 `KeyframeTrack`（关键帧轨迹）。
3.  在每个轨迹中，我们定义了一系列 `CubicKeyframe`。例如，对于 `scale`，我们让它先在 0.2 秒内变到 1.2，然后再用 0.2 秒回到 1.0。
4.  `KeyframeAnimator` 会自动播放这个时间线，并在 `content` 闭包中提供实时更新的 `values`。我们将这些 `values` 应用到 `Image` 的 `scaleEffect` 和 `offset` 上，从而实现了跳动效果。
5.  `trigger` 参数监听 `startAnimation` 的变化，每次 `startAnimation` 改变时，都会重新播放整个关键帧动画。

## 关键帧类型 (`Keyframe`)

SwiftUI 提供了几种不同类型的关键帧，以控制值与值之间的过渡方式：

*   **`LinearKeyframe`**: 线性过渡。值在指定 `duration` 内均匀地从当前值变化到目标值。
*   **`CubicKeyframe`**: 三次贝塞尔曲线过渡。这是最常用的类型，它提供了一个平滑的、缓入缓出的效果。
*   **`SpringKeyframe`**: 弹簧动画过渡。你可以指定弹簧的 `stiffness` (刚度) 和 `damping` (阻尼) 等物理参数，来创建富有弹性的物理效果。
*   **`MoveKeyframe`**: 瞬间移动。值会立即跳变到目标值，没有过渡动画。

```swift
KeyframeTrack(\.rotation) {
    SpringKeyframe(.degrees(30), duration: 0.3, spring: .bouncy)
    SpringKeyframe(.degrees(-30), duration: 0.3, spring: .bouncy)
    SpringKeyframe(.zero, duration: 0.3, spring: .bouncy)
}
```

## `PhaseAnimator` vs. `KeyframeAnimator`

`PhaseAnimator` 和 `KeyframeAnimator` 都是 iOS 17 中引入的、用于创建多阶段动画的工具，但它们的侧重点不同。

*   **`PhaseAnimator`**: **基于阶段 (Phase-based)**。你定义一组离散的动画“阶段”（通常是一个枚举），并为每个阶段指定一个最终的外观。SwiftUI 负责在这些阶段之间进行动画过渡。它更适合用于**循环的、状态机式**的动画。

*   **`KeyframeAnimator`**: **基于时间线 (Timeline-based)**。你精确地定义了在动画时间线上的**特定时间点**，某个属性应该达到的**具体值**。它更适合用于**一次性的、具有复杂时序和路径**的动画。

简单来说，`PhaseAnimator` 关心的是“去哪里”（目标状态），而 `KeyframeAnimator` 不仅关心“去哪里”，还关心“什么时间去”以及“怎么去”（动画曲线）。

## 总结

`KeyframeAnimator` 是 SwiftUI 动画系统中一个极其强大的新成员，它将专业动画软件中“关键帧”和“时间线”的概念，以一种声明式的方式引入了 SwiftUI。

*   **精确控制**: 允许你精确地编排一个或多个动画属性随时间变化的过程。
*   **复杂时序**: 可以轻松创建多步骤、非线性的复杂动画序列。
*   **声明式**: 将复杂的动画逻辑封装在一个独立的视图中，代码结构清晰，易于理解和维护。
*   **物理效果**: 通过 `SpringKeyframe`，可以轻松地集成逼真的弹簧动画。

当你需要创建一个超越简单 `withAnimation` 的、具有电影般质感的、精心编排的动画序列时，`KeyframeAnimator` 是你的终极武器。
