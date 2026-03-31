# Apple AI 框架：Translation

`Translation` 框架是苹果在 WWDC 2023 (iOS 17) 中推出的一个全新的、强大的翻译 API。它将苹果系统级的翻译能力——即你在“翻译”应用或 Safari 浏览器中看到的翻译功能——直接开放给了第三方开发者。

通过 `Translation` 框架，你可以轻松地在你的应用中实现高质量的文本翻译，并且可以选择在**端侧（On-Device）**或**云端（Cloud）**进行。

## 核心理念：简单、强大、注重隐私

*   **高质量翻译**: 使用与苹果自家应用相同的、经过优化的神经网络翻译引擎。
*   **端侧优先**: 许多语言对之间的翻译可以直接在设备上离线完成，这保证了极快的速度和最高级别的用户隐私。
*   **自动回退**: 如果某个语言对的翻译模型在设备上不可用，框架会自动、无缝地回退到苹果的云端翻译服务器。
*   **简洁的 API**: 提供了基于 `async/await` 的现代化 Swift API，使用起来非常简单。

## 核心用法：`TranslationSession`

进行翻译的主要入口是 `TranslationSession`。你需要创建一个 `TranslationSession` 的实例，并调用它的 `translate(_:)` 异步方法。

### 1. 请求授权 (仅限云端)

如果你需要使用云端翻译（例如，处理端侧不支持的语言），你必须在 `Info.plist` 文件中添加 `NSTranslationUsageDescription` 键，并提供一个字符串来向用户解释你为什么需要访问苹果的翻译服务。

### 2. 执行翻译

```swift
import SwiftUI
import Translation

struct TranslationExample: View {
    @State private var inputText = "Hello, world!"
    @State private var translatedText = ""
    @State private var isTranslating = false

    // 1. 创建一个 TranslationSession 实例
    // 你可以为 session 指定一个策略，例如 .deviceOnly
    let session = TranslationSession(configuration: .init())

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("输入文本 (英语):")
            TextEditor(text: $inputText)
                .frame(height: 100)
                .border(Color.gray)
            
            Button("翻译成中文") {
                Task {
                    await translateText()
                }
            }
            
            if isTranslating {
                ProgressView()
            } else {
                Text("翻译结果:")
                Text(translatedText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
        }
        .padding()
    }

    func translateText() async {
        isTranslating = true
        do {
            // 2. 准备翻译请求
            let request = TranslationRequest(source: inputText)
            
            // 3. 调用 translate 方法
            let response = try await session.translate(request)
            
            // 4. 更新 UI
            translatedText = response.targetText
            
        } catch {
            translatedText = "翻译失败: \(error.localizedDescription)"
        }
        isTranslating = false
    }
}

#Preview {
    TranslationExample()
}
```

在这个例子中：
1.  我们创建了一个 `TranslationSession` 的实例。
2.  在 `translateText` 异步函数中，我们用输入的文本创建了一个 `TranslationRequest`。
3.  我们 `await session.translate(request)` 来执行翻译。这个方法会自动处理端侧和云端的选择。
4.  成功后，我们从返回的 `TranslationResponse` 中获取 `targetText` 并更新 UI。

## 配置 `TranslationSession`

在创建 `TranslationSession` 时，你可以提供一个 `TranslationSession.Configuration` 对象来定制其行为。

```swift
let configuration = TranslationSession.Configuration()

// 1. 指定翻译策略
// .deviceOnly: 强制只使用端侧翻译，如果不支持则会失败
// .deviceFirst: 优先使用端侧，如果不支持则自动回退到云端 (默认)
configuration.policy = .deviceOnly

// 2. (可选) 指定目标语言
// 如果不指定，系统会尝试使用应用的当前语言
configuration.targetLocale = Locale(identifier: "zh-CN")

let session = TranslationSession(configuration: configuration)
```

## `Translation` vs. 第三方翻译 API

| 特性 | Apple `Translation` 框架 | 第三方 API (如 Google Translate) |
| :--- | :--- | :--- |
| **隐私** | **极高**。支持完全离线的端侧翻译。 | 数据需要发送到第三方服务器，存在隐私风险。 |
| **成本** | **免费**（在苹果的合理使用范围内）。 | 通常按字符数或请求次数收费。 |
| **集成** | **原生**。与 Swift `async/await` 无缝集成。 | 需要处理网络请求、API 密钥管理、JSON 解析等。 |
| **离线能力** | **支持**。 | 不支持。 |
| **语言支持** | 支持的语言对数量相对较少，但覆盖了主流语言。 | 通常支持更广泛的语言。 |

**选择建议**：
*   对于绝大多数需要在苹果平台应用中集成翻译功能的场景，**应优先使用苹果官方的 `Translation` 框架**。它提供了最佳的性能、隐私保护和系统集成度。
*   只有当你需要翻译 `Translation` 框架不支持的、非常小众的语言时，才需要考虑使用第三方的云端翻译 API。

## 总结

`Translation` 框架是苹果向开发者开放其核心 AI 能力的一个重要里程碑。它将一个原本需要依赖昂贵、复杂的第三方云服务的核心功能，变成了一个简单、安全、高效的原生 API。

*   **简单强大**: 通过 `TranslationSession` 和 `async/await`，只需几行代码即可实现高质量的文本翻译。
*   **隐私为先**: 支持完全在设备上进行的离线翻译，保护了用户数据的隐私。
*   **智能回退**: 在端侧能力不足时，可以自动、无缝地切换到云端翻译。

通过使用 `Translation` 框架，你可以轻松地为你的应用添加跨语言沟通的能力，打破语言障碍，触达更广泛的全球用户。
