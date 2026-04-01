# 在 App 中使用大型语言模型 (LLM)

将大型语言模型（Large Language Models, LLM），如 GPT、Gemini、Claude 等，集成到你的移动应用中，可以创造出强大的、富有创造性的、对话式的用户体验。然而，这不仅仅是简单地调用一个 API，它需要一套完整的架构设计和对用户体验的深度思考。

## 架构选择：端侧 vs. 云端

1.  **端侧模型 (On-Device)**: 
    *   **方式**: 使用 Core ML 或 MLX 运行经过优化的、较小的语言模型（如 DistilBERT, TinyLlama）。
    *   **优点**: 隐私性好、无网络依赖、响应快、无 API 成本。
    *   **缺点**: 模型能力有限，通常只能处理特定的 NLP 任务（如文本分类、情感分析），无法进行复杂的、开放域的对话或内容生成。

2.  **云端模型 (Cloud-based)**: 
    *   **方式**: 通过网络 API 调用由 OpenAI, Google, Anthropic 等公司提供的强大的 LLM 服务。
    *   **优点**: 模型能力极强，可以处理几乎任何语言任务。
    *   **缺点**: 依赖网络、有延迟、API 成本高、存在数据隐私风险。

**最佳实践**: 对于需要真正“智能”的、生成式的、对话式的应用，**云端模型是目前唯一的选择**。端侧模型可以作为辅助，用于在调用云端 API 之前，进行一些预处理或意图识别。

## 核心工作流：构建一个聊天界面

让我们以构建一个简单的、与 LLM 对话的聊天应用为例，来梳理其核心工作流。

### 1. 构建 API 网关 (Backend for Frontend)

**永远不要在你的客户端 App 中直接调用第三方 LLM 的 API！** 这会将你的 API 密钥暴露给用户，带来巨大的安全风险和成本失控的可能。

你需要创建一个自己的后端服务，作为“API 网关”：
*   **客户端**只与你的**API 网关**通信。
*   **API 网关**负责安全地管理你的 API 密钥，并代表客户端去调用真正的 LLM API。
*   **API 网关**还可以实现缓存、速率限制、日志记录、成本监控等关键功能。

### 2. 实现流式响应 (Streaming)

LLM 生成一个完整的答案可能需要几秒甚至几十秒。让用户长时间地盯着一个加载指示器，是极差的用户体验。

**流式响应是构建良好 LLM 应用体验的黄金标准。**

*   **工作原理**: LLM API 通常支持流式模式。当你发送一个请求时，它不会等到生成完所有内容再返回，而是会像打字机一样，每生成一个或几个词（token），就立即通过一个持久的 HTTP 连接，将这个“数据块”（chunk）发送回来。
*   **后端实现**: 你的 API 网关需要支持流式传输，将从 LLM API 收到的数据块实时地转发给客户端。
*   **客户端实现**: 
    *   使用 `URLSession` 的 `bytes(for:)` 异步序列，来接收这些流式数据块。
    *   每收到一个新的数据块，就将其解码，并追加到你用于显示文本的 `@Published` 变量上。
    *   SwiftUI 会自动地、增量地更新 `Text` 视图，从而实现打字机效果。

### 3. 提示词工程与上下文管理

*   **系统提示词 (System Prompt)**: 在开始一次对话之前，先向 LLM 发送一个“系统提示词”，来为它设定角色、个性和行为准则。例如：“你是一个乐于助人的 Swift 编程专家。你的回答应该简洁、准确，并总是提供代码示例。”

*   **维护对话历史**: LLM 本身是无状态的。为了让它能够“记住”之前的对话内容，你必须在每次发送新请求时，将**整个对话历史**（包括用户和 AI 之前的所有消息）都一并发送给它。这被称为**上下文窗口（Context Window）**。

    ```json
    {
        "model": "gpt-4",
        "messages": [
            { "role": "system", "content": "你是一个 Swift 专家。" },
            { "role": "user", "content": "什么是 @State？" },
            { "role": "assistant", "content": "@State 是一个..." },
            { "role": "user", "content": "那它和 @Binding 有什么区别？" } // 这是新的问题
        ]
    }
    ```

*   **上下文窗口限制**: 每个模型都有一个上下文窗口的长度限制（例如 4k, 8k, 128k tokens）。当对话历史变得过长时，你需要采用一些策略来截断它，例如只保留最近的 10 轮对话。

### 4. 在 SwiftUI 中实现

```swift
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var currentInput = ""
    
    private var apiGateway = APIGateway()
    
    func sendMessage() {
        let userMessage = Message(content: currentInput, role: .user)
        messages.append(userMessage)
        currentInput = ""
        
        let assistantMessage = Message(content: "", role: .assistant)
        messages.append(assistantMessage)
        
        Task {
            // 1. 调用你的 API 网关，并传入对话历史
            let stream = apiGateway.streamResponse(for: messages)
            
            // 2. 异步地遍历返回的数据块流
            for try await chunk in stream {
                // 3. 将新的文本块追加到最后一条消息上
                messages[messages.count - 1].content += chunk
            }
        }
    }
}

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        VStack {
            ScrollView { ... }
            HStack {
                TextField("输入消息...", text: $viewModel.currentInput)
                Button("发送") { viewModel.sendMessage() }
            }
        }
    }
}
```

## 总结

在应用中成功集成 LLM，是一个涉及前后端、产品设计和用户体验的系统工程。

*   **架构**: **必须**使用你自己的**后端 API 网关**来管理 API 密钥和请求，绝对不能在客户端直接调用第三方 API。
*   **用户体验**: **必须**使用**流式响应（Streaming）**来提供实时的打字机效果，以降低用户的等待焦虑。
*   **核心逻辑**: 通过**系统提示词**来设定 AI 的行为，并通过维护**对话历史**来为 AI 提供上下文。
*   **成本与性能**: 考虑为常见请求添加**缓存**，并注意管理上下文窗口的长度。

通过遵循这些最佳实践，你可以构建出一个功能强大、体验流畅、安全可靠的 AI 对话应用。
