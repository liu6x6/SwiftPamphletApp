# Combine 处理网络请求 (URLSession)

网络请求是 Combine 最具统治力、也是最能展示其“流式处理”和“错误处理”魅力的场景。在 Swift Concurrency (async/await) 普及之前，使用 Combine 的 \`URLSession.dataTaskPublisher\` 是苹果官方最推荐的现代网络架构。

## 1. 传统的闭包网络请求痛点

在以前，写一个自带 JSON 解析和错误处理的网络请求，会充满 \`guard let\` 和深深嵌套的闭包。而且很容易在非主线程更新 UI 导致崩溃。

## 2. Combine 网络请求的标准模板

Apple 为 \`URLSession\` 提供了一个原生扩展方法：\`dataTaskPublisher(for:)\`。它天然就是一个发回 \`(Data, URLResponse)\` 元组的发布者。

下面是一个极其优雅、包含完整生命周期的现代网络请求流水线：

```swift
import Foundation
import Combine

// 1. 定义期望解析的数据模型
struct UserProfile: Codable {
    let id: Int
    let name: String
}

class NetworkService {
    var cancellables = Set<AnyCancellable>()
    
    func fetchUser() {
        let url = URL(string: "https://api.example.com/user/1")!
        
        // 1. 发起请求：自动在后台线程执行
        URLSession.shared.dataTaskPublisher(for: url)
            
            // 2. 初步过滤：只取成功的 HTTP 状态码
            .tryMap { (data, response) -> Data in
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    // 如果状态码不对，直接抛出我们自定义的异常，流立刻中断！
                    throw URLError(.badServerResponse)
                }
                // 如果没问题，只把最核心的纯 Data 交给下一道工序
                return data
            }
            
            // 3. 数据解析：这是 Combine 提供的官方神技，直接一步把 Data 解码成对象
            .decode(type: UserProfile.self, decoder: JSONDecoder())
            
            // 4. (可选) 错误降级与兜底：如果上面网断了或者 JSON 崩了
            // 可以使用 catch 拦截并返回一个系统预设的安全值（利用 Just）
            // .catch { _ in Just(UserProfile(id: -1, name: "匿名用户")) }
            
            // 5. 线程切换：这是铁律！网络请求和 JSON 解析都是在后台队列干的，
            // 现在我们要把最终的活蹦乱跳的 UserProfile 对象交回给主线程，以备 UI 渲染。
            .receive(on: DispatchQueue.main)
            
            // 6. 最终落脚点：拿到成果
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("网络请求链路完美结束")
                    case .failure(let error):
                        // 统一错误处理中心
                        print("抱歉，请求过程中发生了致命错误：\(error)")
                    }
                },
                receiveValue: { user in
                    print("完美解析出对象，名字是: \(user.name)")
                    // self.updateUI(with: user)
                }
            )
            .store(in: &cancellables) // 保存凭证防止流提前销毁
    }
}
```

## 3. 高级玩法：优雅的重试机制 (Retry)

在移动网络极不稳定的环境下，偶尔的超时断连很正常。在老代码中写重试逻辑非常恶心。在 Combine 中，只需要一个单词：

```swift
URLSession.shared.dataTaskPublisher(for: url)
    // 如果发生错误，直接再试一次！最多重试 3 次！
    .retry(3) 
    .map(\.data)
    .decode(...)
```

## 4. 与 Swift async/await 的比较选择

从 iOS 15 开始，网络请求也可以用 `try await URLSession.shared.data(from: url)`。

**该怎么选？**
*   **单一的一次性请求**：如果你只是点一下按钮去请求一段 JSON 然后显示，**强烈建议使用更新的 `async/await`**，代码会从链式变成纯线性的，更容易阅读。
*   **流式处理或复杂联动**：如果是“每隔 3 秒请求一次 API，拿最新的股票数据去更新 UI，并且一旦报错就重试 3 次，如果连续 3 次失败就把流切换到本地数据库读取旧缓存”——这种涉及到**时间维度、重试重定向和多重数据合并**的变态需求，**Combine 的操作符生态依然能秒杀 `async/await`。**
