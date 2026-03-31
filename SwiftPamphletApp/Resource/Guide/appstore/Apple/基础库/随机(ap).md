# Swift 中的随机数生成 (Randomness)

在 Swift 4.2 及其之后的版本中，Apple 彻底抛弃了古老且丑陋的 C 语言函数 `arc4random_uniform()` 和 `srand()`。Swift 引入了一套原生的、类型安全的、并且**默认密码学安全 (Cryptographically Secure)** 的随机数 API。

## 1. 最基础的随机数：`.random(in:)`

这是你使用最频繁的 API。所有的基础数值类型（`Int`, `Double`, `Float`, `CGFloat` 甚至 `Bool`）都直接内置了这个静态方法。

```swift
// 生成一个 1 到 100 之间的随机整数（包含 1 和 100）
let randomInt = Int.random(in: 1...100)

// 生成一个 0.0 到 1.0 之间的随机浮点数（不包含 1.0）
let randomDouble = Double.random(in: 0.0..<1.0)

// 抛硬币，直接随机生成一个布尔值
let isHeads = Bool.random()
```

## 2. 集合的随机操作：`.randomElement()` 与 `.shuffled()`

如果你有一个数组（或者任何遵循 `Collection` 协议的集合），你可以非常优雅地对其进行随机操作。

```swift
let names = ["Alice", "Bob", "Charlie", "David"]

// 1. 随机抽取一个元素 (类似于抽奖)
// 注意：如果数组是空的，它会安全地返回 nil，所以它是 Optional
if let winner = names.randomElement() {
    print("中奖者是：\(winner)")
}

// 2. 将数组里的元素顺序彻底打乱 (类似于洗牌)
// 返回一个全新的、被洗切过的数组
let shuffledNames = names.shuffled()

// 3. 如果是用 var 声明的可变数组，可以原地洗牌
var deckOfCards = [1, 2, 3, 4, 5]
deckOfCards.shuffle() // 原地打乱
```

## 3. 密码学安全的底层原理：SystemRandomNumberGenerator

在很多语言（比如老版本的 JS 或 C）中，默认的随机函数生成的都是**伪随机数 (Pseudo-Random)**。如果你知道了随机种子（Seed），你就能完美预测出接下来的每一个数字。这在编写抽奖系统或生成加密密钥时是极其危险的。

**Swift 的伟大之处在于，当你调用 `Int.random(in:)` 时，它底层默认使用的是 `SystemRandomNumberGenerator`。**

这个生成器直接连接到了操作系统的底层安全熵源（如 macOS 的 `/dev/urandom`）。这意味着它生成的数字是**密码学安全**的，即使是最高明的黑客也无法通过前面的数字预测出下一个结果。你可以放心地用它来生成临时的密码、验证码。

## 4. 自定义随机数生成器 (Custom Generator)

如果默认的“绝对不可预测”不符合你的需求怎么办？

假设你在开发一个“随机迷宫生成”游戏（如《Minecraft》的地图种子），你希望：只要玩家输入相同的“种子码（Seed）”，系统每次生成的看似随机的迷宫结构都必须**一模一样**。
这就要求随机数是可预测的伪随机。

这时候，你需要自己实现一个遵循 `RandomNumberGenerator` 协议的结构体（例如使用经典的线性同余或梅森旋转算法），然后把它作为参数传给 random 方法：

```swift
// 假设你或者第三方库实现了一个基于种子的可预测生成器
var mySeededGenerator = MyPredictableGenerator(seed: 12345)

// 将你的生成器传给 inout 参数
let randomA = Int.random(in: 1...100, using: &mySeededGenerator)
let randomB = Int.random(in: 1...100, using: &mySeededGenerator)

// 只要 seed 还是 12345，无论你运行多少次 App，randomA 和 randomB 的结果都将永恒不变。
```

## 总结
*   日常业务开发，无脑使用 `类型.random(in:)` 和 `数组.randomElement()`。它们安全、优雅、性能极高。
*   绝对不需要再去调用 `arc4random` 甚至做任何取模求余（`%`）的运算（那会导致模偏差 Modulo Bias 问题）。
