# Apple AI：文本处理框架与能力

在苹果的 AI 技术栈中，处理和理解文本是其核心能力之一。苹果提供了一系列从底层到高层的框架，让开发者能够在其应用中集成各种强大的自然语言处理（Natural Language Processing, NLP）功能。这些功能在 Apple Intelligence 的加持下，变得更加智能和个人化。

## 1. `NaturalLanguage` 框架

`NaturalLanguage` 框架是苹果提供的、用于在端侧进行各种 NLP 任务的基础框架。它提供了丰富的 API 来分析和理解文本。

*   **语言识别 (`NLLanguageRecognizer`)**: 检测一段文本所使用的语言。

    ```swift
    import NaturalLanguage
    let recognizer = NLLanguageRecognizer()
    recognizer.processString("Hello, world!")
    if let language = recognizer.dominantLanguage {
        print(language.rawValue) // 输出 "en"
    }
    ```

*   **分词 (`NLTokenizer`)**: 将一段文本分解为更小的单元，如单词、句子或段落。

    ```swift
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.string = "This is a sample sentence."
    tokenizer.enumerateTokens(in: tokenizer.string!.startIndex..<tokenizer.string!.endIndex) { tokenRange, _ in
        print(tokenizer.string![tokenRange]) // 依次输出 "This", "is", "a", ...
        return true
    }
    ```

*   **词性标注 (`NLTagger`)**: 识别文本中每个词的词性（如名词、动词、形容词）。

*   **命名实体识别 (`NLTagger`)**: 从文本中识别出人名、地名、组织名等专有名词。

*   **情感分析 (`NLTagger`)**: 评估一段文本所表达的情感倾向（积极、消极或中性）。

*   **词向量 (`NLEmbedding`)**: 获取单词的向量表示。在向量空间中，语义相近的词（如“国王”和“女王”）它们的向量也更接近。这对于计算文本相似度、进行文本分类等高级任务非常有用。

## 2. `Translation` 框架 (iOS 17+)

这是一个全新的、现代化的翻译框架，提供了高质量的、支持端侧离线的文本翻译功能。

*   **核心**: `TranslationSession` 和 `async/await` API。
*   **优势**: 隐私保护、免费、与系统无缝集成。

（更多详情请参阅 `人工智能-Translation(ap).md`）

## 3. `Vision` 框架中的文本识别 (OCR)

`Vision` 框架提供了强大的光学字符识别（Optical Character Recognition, OCR）功能，可以从**图像**或**摄像头实时视频流**中检测和识别文本。

*   **核心请求**: `VNRecognizeTextRequest`。
*   **功能**: 
    *   **快速模式**: 速度快，但准确率稍低。
    *   **准确模式**: 准确率更高，但需要更多计算资源。
    *   **语言支持**: 支持多种语言的识别。
    *   **实时文本识别 (Live Text)**: 从 iOS 15 开始，系统级别的“实况文本”功能就是基于此技术。开发者也可以通过 `Interaction` API 将类似的功能集成到自己的应用中。

## 4. Apple Intelligence 中的写作工具 (Writing Tools) (iOS 18+)

这是苹果在系统层面提供的、由大型语言模型驱动的、最顶层的文本处理能力。

*   **核心功能**: 
    *   **改写 (Rewrite)**: 调整文本的语气和风格。
    *   **校对 (Proofread)**: 检查语法、措辞和句子结构。
    *   **总结 (Summarize)**: 将长文本提炼为要点、表格或段落。
*   **集成**: 对于使用标准 `TextField` 和 `TextEditor` 的应用，将**自动获得**这些功能。第三方开发者也可以通过新的 `WritingTools` API 来进行深度集成。

## 5. 与大型语言模型 (LLM) 的交互

当端侧的框架无法满足你的需求时（例如，你需要进行开放域的问答、写一首诗或生成一篇完整的文章），你就需要与云端的 LLM API 进行交互。

*   **SiriKit & App Intents**: 这是让你的应用功能被 Siri 和 Apple Intelligence **调用**的方式。你可以将你的文本处理功能（例如，“将这段文字翻译成火星文”）封装成一个 `AppIntent`，从而让系统可以调用它。

*   **直接调用 API**: 你的应用可以通过自己的后端服务（API 网关），来调用 OpenAI (GPT), Google (Gemini) 等第三方 LLM 的 API。在这种模式下，你需要自己处理网络请求、流式响应、提示词工程和上下文管理。

## 架构选择建议

*   **我需要识别一段文本的语言或情感？** -> 使用 `NaturalLanguage` 框架。
*   **我需要从图片中提取文字？** -> 使用 `Vision` 框架的 `VNRecognizeTextRequest`。
*   **我需要在应用内提供高质量的文本翻译？** -> 使用 `Translation` 框架。
*   **我希望用户能方便地改写或总结他们输入的文本？** -> 升级到 iOS 18，`TextField` 和 `TextEditor` 会自动支持 **Writing Tools**。
*   **我需要生成一篇全新的文章或进行开放式的对话？** -> 通过后端服务，调用**云端 LLM API**。
*   **我希望 Siri 能调用我应用中的文本处理功能？** -> 将你的功能封装成 **`AppIntent`**。

## 总结

苹果为开发者提供了一个从底层到顶层、从端侧到云端的、完整的文本处理 AI 技术栈。

*   **基础分析**: `NaturalLanguage` 框架提供了丰富的、在端侧运行的 NLP 基础工具。
*   **特定任务**: `Vision` 和 `Translation` 框架为 OCR 和翻译等常见高级任务提供了专门的、高性能的解决方案。
*   **生成与创作**: Apple Intelligence 的 **Writing Tools** 将 LLM 的强大生成能力，以一种系统级服务的方式，带给了所有应用。
*   **开放性**: `App Intents` 和对第三方 LLM API 的支持，为开发者提供了无限的扩展可能性。

通过理解并组合使用这些框架，你可以在你的应用中实现各种复杂的、智能化的文本处理功能，极大地提升应用的功能深度和用户体验。
