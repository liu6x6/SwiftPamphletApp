# 处理没有 id 字段的 JSON 解析 (Identifiable)

在 SwiftUI 中渲染列表 (\`List\`, \`ForEach\`) 时，数据模型通常需要遵循 \`Identifiable\` 协议，这意味着模型必须有一个名为 \`id\` 的唯一标识符。然而，很多时候后端的旧接口或者第三方的 JSON 数据里并没有 \`id\` 这个字段，可能会叫 \`userId\`, \`uuid\`, 或者压根就没有唯一标识。

## 场景一：JSON 中有唯一标识，但不叫 \`id\`

假设后端返回的 JSON 如下：
\`\`\`json
{
    "user_token": "A123",
    "name": "Alice"
}
\`\`\`

### 错误做法：直接改属性名
如果你直接把属性写成 \`let id: String\`，\`JSONDecoder\` 会因为找不到名为 "id" 的 JSON 键而崩溃。

### 优雅解法 1：使用 \`CodingKeys\` 映射
这是最标准的解法。让模型遵循 \`Identifiable\` 和 \`Codable\`，然后通过 \`CodingKeys\` 告诉解码器：JSON 里的 "user_token" 就是模型里的 "id"。

```swift
struct User: Identifiable, Codable {
    let id: String
    let name: String
    
    // 自定义键名映射
    enum CodingKeys: String, CodingKey {
        case id = "user_token"
        case name
    }
}
```

### 优雅解法 2：使用计算属性 (Computed Property)
如果你想在代码中保留 \`userToken\` 这个具有业务语义的命名，你可以只声明一个满足 \`Identifiable\` 协议的计算属性。

```swift
struct User: Identifiable, Codable {
    let userToken: String
    let name: String
    
    // 满足 Identifiable 协议，只读不写，不需要参与 Codable 的解析
    var id: String { userToken }
    
    // 需要使用 .convertFromSnakeCase 的解码策略来将 user_token 转为 userToken
}
```

## 场景二：JSON 中彻底没有任何唯一标识

假设后端返回的仅仅是一个简单的字符串数组，或者是一个缺乏唯一主键的字典数组：
\`\`\`json
[
    { "name": "Apple", "price": 10 },
    { "name": "Apple", "price": 10 } 
]
\`\`\`

### 优雅解法：UUID() 注入
由于 SwiftUI 的列表需要唯一标识来计算动画和差异，如果数据完全一样且没 id，会导致视图渲染崩溃或错乱。我们可以在 Swift 结构体初始化时，**手动为其注入一个 UUID**。

```swift
struct Product: Identifiable, Codable {
    // 1. 使用 let 声明 id 并给它一个默认值 UUID()
    // 由于我们没有在 CodingKeys 里包含它，JSONDecoder 会忽略这个字段，
    // Swift 就会使用我们提供的默认值 (一个每次初始化都不一样的随机 UUID)
    let id = UUID()
    
    let name: String
    let price: Int
    
    // 2. 注意：如果你不写 CodingKeys，Swift 默认会尝试去 JSON 里找 "id" 并报错。
    // 所以必须显式声明 CodingKeys，把 id 排除在外！
    enum CodingKeys: String, CodingKey {
        case name, price
    }
}
```

### 降级解法：在 ForEach 中使用索引
如果仅仅是极其简单的只读静态展示，你甚至不需要让模型遵循 \`Identifiable\`，而是利用数组的索引作为标识（极度不推荐用于涉及删除/移动的动态列表）。

```swift
struct SimpleView: View {
    let rawProducts: [Product] // 假设 Product 没有 id

    var body: some View {
        // 使用 \.self 如果元素是 Hashable
        // 或者使用数组的 indices
        ForEach(rawProducts.indices, id: \.self) { index in
            Text(rawProducts[index].name)
        }
    }
}
```
*永远优先考虑在数据模型层（通过 \`UUID\` 或计算属性）解决 \`id\` 问题，而不是在 UI 渲染层妥协。*
