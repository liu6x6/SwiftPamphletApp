# Apple AI：SiriKit 与 App Intents

SiriKit 和 App Intents 是苹果提供的两大核心框架，它们允许你的应用将其功能和服务“暴露”给操作系统，从而让用户可以通过 Siri、快捷指令（Shortcuts）以及系统其他部分（如聚焦搜索 Spotlight）来直接与你的应用进行交互。

随着 Apple Intelligence 的推出，这两个框架的重要性被提升到了前所未有的高度。一个深度集成了 App Intents 的应用，将能够无缝地融入到由 Apple Intelligence 驱动的、更智能、更具情境感知能力的 Siri 体验中。

## SiriKit：早期的意图框架

SiriKit 是苹果最早推出的、用于将应用功能集成到 Siri 的框架。它定义了一系列预设的“领域”（Domains），如消息（Messaging）、支付（Payments）、锻炼（Workouts）、打车（Ride Booking）等。

*   **工作方式**: 
    1.  你的应用需要声明它支持哪个领域的意图（Intent）。
    2.  你需要创建一个“意图扩展”（Intents Extension）。
    3.  当用户通过 Siri 说出一个符合该领域意图的指令时（例如“用 MyChatApp 发消息给小明说我晚到 5 分钟”），系统会将这个意图路由到你的扩展中。
    4.  你的扩展负责处理这个意图，并向 Siri 提供一个用于显示的 UI。
*   **局限性**: SiriKit 非常僵化。你只能实现苹果预先定义好的那些领域的意图，无法支持你应用中独特的、自定义的功能。

## App Intents：现代化的意图框架

为了解决 SiriKit 的局限性，苹果推出了 `AppIntents` 框架。这是一个更现代、更灵活、更强大的意图定义和集成框架。它完全使用 Swift 编写，并采用了声明式的语法。

通过 `AppIntents`，你可以将你应用中的**任何功能**，封装成一个可被系统理解和调用的“意图”（Intent）。

### 核心理念：定义你的“动作”

`AppIntents` 的核心是创建一个遵循 `AppIntent` 协议的结构体。这个结构体代表了你的应用可以执行的一个独立“动作”。

你需要：
1.  **定义 `AppIntent` 结构体**: 包含该动作所需的所有参数。
2.  **提供元数据**: 通过 `title`, `description` 等静态属性，向系统描述这个动作是什么。
3.  **实现 `perform()` 方法**: 在这个异步方法中，编写执行该动作的实际逻辑。

```swift
import SwiftUI
import AppIntents

// 1. 定义一个 App Intent
struct AddToReadingListIntent: AppIntent {
    // 2. 定义元数据
    static var title: LocalizedStringResource = "添加到阅读列表"
    static var description = IntentDescription("将一个 URL 添加到你的应用阅读列表中。")
    
    // 3. 定义参数
    @Parameter(title: "URL")
    var url: URL
    
    // 4. 实现 perform 方法
    @MainActor // 确保在主线程上执行
    func perform() async throws -> some IntentResult {
        // 在这里执行你的应用逻辑，例如将 url 保存到数据库
        ReadingListManager.shared.add(url: url)
        return .result()
    }
}
```

### 将意图暴露给系统

一旦你定义好了一个 `AppIntent`，系统就可以在多个地方发现并使用它：

*   **快捷指令 (Shortcuts)**: 你的 `AddToReadingListIntent` 会自动出现在“快捷指令”应用的操作库中。用户可以将它与其他应用的动作组合起来，创建强大的自动化工作流。

*   **Siri**: 用户可以直接通过 Siri 调用它：“嘿 Siri，用 MyReadingApp 添加这个链接到阅读列表”。

*   **小组件交互 (iOS 17+)**: 你可以将一个 `AppIntent` 实例直接绑定到一个 SwiftUI 的 `Button` 上，以创建可交互的小组件。

    ```swift
    // 在小组件视图中
    Button(intent: AddToReadingListIntent(url: article.url)) {
        Label("稍后阅读", systemImage: "book")
    }
    ```

### 与 Apple Intelligence 的集成

Apple Intelligence 将 `App Intents` 的能力提升到了一个新的高度。

*   **更智能的 Siri**: 新版 Siri 能够更深入地理解用户意图，并自动地、无需用户明确说出应用名称，就能调用你应用中定义的 `AppIntent`。例如，当用户在一个新闻 App 中浏览时，他们可能只需要说“把这个加到我的阅读列表里”，Siri 就能理解“这个”指的是当前文章的 URL，并自动调用你的 `AddToReadingListIntent`。
*   **应用间协作**: Siri 可以将多个来自不同应用的 `AppIntent` 串联起来，以完成一个复杂的用户请求。例如，“把小明上周发给我的那张照片，用 PixelEditor 应用加上一个复古滤镜，然后发给妈妈”。这个指令可能就串联了“照片”应用的搜索意图、`PixelEditor` 的滤镜意图和“信息”应用的发送意图。

## 总结

`AppIntents` 框架是你的应用与 Apple Intelligence 和整个操作系统生态进行集成的“官方语言”。

*   **声明式**: 使用 Swift 结构体和属性包装器来清晰地定义应用的“动作”。
*   **统一入口**: 为 Siri、快捷指令、小组件交互和未来的系统级 AI 功能，提供了单一、统一的集成点。
*   **自动化**: 你只需定义好你的意图，系统会自动处理自然语言理解、参数提取和用户界面的呈现。
*   **未来的方向**: 深度集成 `AppIntents`，是确保你的应用能够在由 Apple Intelligence 驱动的、更智能、更具情境感知能力的下一代操作系统中保持竞争力的关键。

通过将你的应用核心功能封装成一个个独立的 `AppIntent`，你不仅仅是在添加“语音控制”，更是在将你的应用从一个孤立的程序，转变为一个可以被系统和其他应用组合、调用的、开放的“服务”。
