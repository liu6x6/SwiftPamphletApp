# zip：拉链般的严格配对组合

在处理多个异步数据流时，如果你需要把不同流里的数据“强行打包在一起”，Combine 提供了好几个合并操作符。其中 **\`zip\`** 的行为是最严格、最讲究规矩的。

它的行为就像衣服上的拉链：**左边拿一颗牙，右边拿一颗牙，完美咬合在一起才能继续往下拉。任何一边缺了，整个拉链就卡住不动。**

## 1. 核心行为准则

当你使用 \`publisherA.zip(publisherB)\` 时：
1.  **强同步等待**：它会从 A 拿第 1 个值，然后死等 B 给出第 1 个值。拿到后，打包成一个元组 \`(a1, b1)\` 发射给下游。
2.  **严格按序号匹配**：A 的第 100 个值，**永远、绝对**只会和 B 的第 100 个值组装在一起。即使 A 瞬间发射了 100 个值，而 B 像蜗牛一样一天才发一个，系统也会把 A 的剩下 99 个值全存在内存缓存里，等着 B 慢慢来配对。
3.  **短板效应 (终止条件)**：如果 A 结束了 (\`.finished\`)，但 B 还在发，\`zip\` 管道会**立刻终止**，因为 A 已经没有牙齿去和 B 的新牙齿咬合了。

## 2. 基础演示

```swift
import Combine

let numbers = PassthroughSubject<Int, Never>()
let letters = PassthroughSubject<String, Never>()

// 将 numbers 和 letters 像拉链一样组合
let cancellable = numbers.zip(letters)
    .sink { (number, letter) in
        print("拉链组合: \(number) - \(letter)")
    }

numbers.send(1)
numbers.send(2)
numbers.send(3)
// 此时控制台没有任何输出！因为 letters 还没发数据，1,2,3 全被 zip 缓冲住了

letters.send("A")
// 瞬间输出: 拉链组合: 1 - A
// 此时内存里还剩 (2, 3) 嗷嗷待哺

letters.send("B")
// 输出: 拉链组合: 2 - B

letters.send("C")
// 输出: 拉链组合: 3 - C

letters.send("D")
// 无输出。因为 numbers 没数据了，"D" 被挂起等待。
```

## 3. 经典实战场景：并行网络请求的统一等待

\`zip\` 最强大的应用场景就是**并行执行多个毫无关联的网络请求，并在它们“全部”成功返回后，统一刷新 UI。**

假设你要进入一个用户主页，必须同时请求“用户基础信息”和“用户的最新文章列表”。如果用原生的 \`async/await\` 你可能会用 \`async let\`。在 Combine 中，就是 \`zip\` 的主场：

```swift
func fetchUserProfile() {
    let profilePublisher = api.getUserInfo()
    let postsPublisher = api.getUserPosts()
    
    // profilePublisher 发出 1 个数据后结束
    // postsPublisher 发出 1 个数据后结束
    profilePublisher.zip(postsPublisher)
        // 切换到主线程
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { completion in
            // 如果其中任何一个请求失败报错 (Failure)，这里的 completion 就是 failure，整个流程中断！
        }, receiveValue: { (profile, posts) in
            // 完美！同时拿到了两者的数据，并且保证它们是同一次页面加载触发的。
            self.userName = profile.name
            self.articleList = posts
        })
        .store(in: &cancellables)
}
```

*注意：Combine 支持最多将 4 个 Publisher 一起 zip 起来：\`Publishers.Zip4(a, b, c, d)\`。*
