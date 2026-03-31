# combineLatest：永远拥抱最新的组合

与极其死板、必须按序号一一配对的 \`zip\` 不同，**\`combineLatest\`** 是一种极其灵活和常见的组合流操作符。

顾名思义，它的核心哲学是：**只要我手底下的任何一条流有了新动静，我就立刻把大家各自“最新”的那个状态抓过来，打包发送出去。**

## 1. 核心行为准则

当你使用 \`publisherA.combineLatest(publisherB)\` 时：
1.  **破冰等待**：一开始，它必须等 A 和 B **都至少发出过一个初始值**。只有大家都有了“最新状态”，它才会发出第一组数据。
2.  **一处更新，整体触发**：破冰之后，只要 A 有新数据，它就拿（A的新数据 + B的旧缓存）发射一次。只要 B 有新数据，它就拿（A的旧缓存 + B的新数据）发射一次。
3.  **不丢弃旧值**：它不像 \`zip\` 那样匹配完就消耗掉。某个流的最新值会一直驻留在内存中，被反复使用，直到该流发出更新的值把它覆盖掉。

## 2. 基础演示

```swift
import Combine

let numSubject = PassthroughSubject<Int, Never>()
let strSubject = PassthroughSubject<String, Never>()

numSubject.combineLatest(strSubject)
    .sink { (num, str) in
        print("最新组合: \(num) - \(str)")
    }

numSubject.send(1)
numSubject.send(2)
// 此时没有任何输出！因为 strSubject 还没有发出过哪怕一个值来破冰。

strSubject.send("A")
// 破冰成功！拿到了 num 的最新值(2) 和 str 的最新值("A")
// 输出: 最新组合: 2 - A

numSubject.send(3)
// num 有了新动静，拿 num的(3) 结合 str保留的("A")
// 输出: 最新组合: 3 - A

strSubject.send("B")
// str 有了新动静
// 输出: 最新组合: 3 - B
```

## 3. 极其经典的实战：表单按钮的联动校验

在写登录注册或者表单页面时，我们经常遇到这样的需求：
*只有当“账号长度 > 6” 且 “密码长度 > 8” 且 “勾选了同意协议” 时，下方的「提交按钮」才允许被点击 (isEnabled = true)。*

用传统的代理或 Target-Action 极其痛苦，你需要在三个控件的回调里互相检查对方的状态。而在 Combine 中，用 \`combineLatest\` 简直是降维打击。

```swift
class FormViewModel: ObservableObject {
    @Published var username = ""
    @Published var password = ""
    @Published var isAgreed = false
    
    // 最终驱动 UI 按钮的状态
    @Published var isSubmitButtonEnabled = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 使用 CombineLatest3 将三个独立的状态流绑在一起
        Publishers.CombineLatest3($username, $password, $isAgreed)
            // 每次任何一个发生变化（比如用户敲了一个字母，或点了一下多选框），
            // 这里都会立刻收到它们三个的“最新全家福”
            .map { (user, pass, agreed) in
                return user.count > 6 && pass.count > 8 && agreed
            }
            // 将布尔值结果绑定给按钮状态
            .assign(to: &$isSubmitButtonEnabled)
    }
}
```
**总结**：只要你的业务逻辑是“由多个不断变化的独立条件，共同推导出一个总的结果”，那么毫无疑问，请直接使用 \`combineLatest\`。
