# Combine 中的通知中心 (NotificationCenter)

在 iOS 开发中，\`NotificationCenter\` 被广泛用于解耦的跨模块通信（比如：键盘弹出、App 进入后台、甚至你自定义的登录成功广播）。

然而，传统的 \`addObserver(forName:object:queue:using:)\` API 有两个大坑：
1. 它在收到通知时，给你的那个闭包常常是地狱的开始，要在里面写大量的 \`if let\` 才能从 \`userInfo\` 字典里扒出真实数据。
2. 极其容易忘记调用 \`removeObserver\` 导致严重的内存泄漏崩溃。

Combine 提供了一个基于流的、极其优雅的 \`NotificationCenter\` 桥接 API。

## 1. 基础用法与自动释放内存

在 Combine 中，获取系统通知只需要一句话。并且只要你的 \`AnyCancellable\` 集合被销毁，通知监听就会绝对安全地被自动移除。

```swift
import UIKit
import Combine

class KeyboardObserver {
    var cancellables = Set<AnyCancellable>()
    
    init() {
        // 核心：把一个通知变成一条无休止的数据流
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { notification in
                // 在这里处理拿到的 notification 对象
                print("系统通知我：键盘马上要弹出来了！")
            }
            // 将“订阅凭证”放入袋子。当 KeyboardObserver 这个类被系统回收时，
            // 袋子里的所有凭证自动销毁，底层自动执行 removeObserver，绝不泄露。
            .store(in: &cancellables)
    }
}
```

## 2. 优雅解析 userInfo (结合 map 和 compactMap)

我们真正需要的通常不是冰冷的 \`Notification\` 对象，而是藏在它 \`userInfo\` 字典里的具体值（比如键盘的高度）。利用 Combine 的管道，我们可以在数据到达 \`sink\` 之前，把脏活累活全处理掉。

```swift
NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
    // 1. 第一步转换：直接尝试从 userInfo 的字典里提取出代表键盘尺寸的 NSValue
    .compactMap { notification -> NSValue? in
        return notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
    }
    // 2. 第二步转换：把 NSValue 解包成实际能用的 CGRect
    .map { nsValue -> CGRect in
        return nsValue.cgRectValue
    }
    // 3. 线程切换：既然下面要更新 UI 调整界面布局，安全起见强制切换到主线程
    .receive(on: RunLoop.main)
    // 4. 终点：到达这里的数据，已经是绝对干净、安全的 CGRect 类型了！
    .sink { keyboardFrame in
        print("精准获取到键盘高度: \(keyboardFrame.height)")
        // 执行你的 UI 动画调整约束...
    }
    .store(in: &cancellables)
```

## 3. 处理自定义业务广播

对于你自定义的跨模块通知，使用 Combine 解析也能大幅降低出错率。

```swift
// 定义一个全局名称
let UserDidLoginNotification = Notification.Name("UserDidLogin")

// 某个深层模块发送广播
let userData = ["userId": 1001, "token": "abc"]
NotificationCenter.default.post(name: UserDidLoginNotification, object: nil, userInfo: userData)

// 全局监听器接收广播
NotificationCenter.default.publisher(for: UserDidLoginNotification)
    // 利用 compactMap 直接过滤掉那些数据格式不对的“劣质广播”
    .compactMap { $0.userInfo?["userId"] as? Int }
    .sink { userId in
        print("收到合法登录通知，开始获取用户 \(userId) 的资料")
    }
    .store(in: &cancellables)
```

## 总结

在现代 iOS 开发中，**只要你的项目部署版本高于 iOS 13，你应该完全抛弃旧的 \`NotificationCenter.default.addObserver\` 方法**，一律使用 \`.publisher(for:)\` 替代。它在代码整洁度和内存安全性上是全方位的降维打击。
