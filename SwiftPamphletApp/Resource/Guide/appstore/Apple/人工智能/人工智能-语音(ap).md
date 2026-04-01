# Apple AI：语音技术框架

语音是人机交互最自然、最高效的方式之一。苹果在其生态系统中，提供了一系列强大的语音技术框架，让开发者能够轻松地为其应用添加语音识别（语音转文本）、语音合成（文本转语音）和声音分析等功能。这些框架在底层都利用了先进的 AI 和机器学习模型。

## 1. `Speech` 框架：语音识别 (Speech-to-Text)

`Speech` 框架提供了将**实时的或预先录制的音频**转换为**文本**的功能。它使用的是与 Siri 和系统键盘听写功能相同的、高质量的语音识别引擎。

### 核心用法

1.  **请求授权**: 语音识别需要访问用户的麦克风和苹果的语音识别服务器，因此必须先请求用户授权。你需要在 `Info.plist` 中添加以下两个键：
    *   `NSSpeechRecognitionUsageDescription`: 请求语音识别权限的说明。
    *   `NSMicrophoneUsageDescription`: 请求麦克风访问权限的说明。

    ```swift
    import Speech

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // ... 在主线程上处理授权状态 ...
        }
    }
    ```

2.  **创建识别请求 (`SFSpeechRecognizer`)**: 创建一个 `SFSpeechRecognizer` 的实例，可以指定一个特定的语言区域（locale）。

3.  **执行识别**: 
    *   **对于音频文件**: 创建一个 `SFSpeechURLRecognitionRequest`。
    *   **对于实时音频流**: 创建一个 `SFSpeechAudioBufferRecognitionRequest`，并使用 `AVFoundation` 的 `AVAudioEngine` 来从麦克风获取音频缓冲区，然后将其 `append` 到请求中。

4.  **处理结果**: 调用 `recognitionTask(with:resultHandler:)` 方法来开始识别。这个任务会通过 `resultHandler` 闭包，持续地返回识别结果，包括中间的、不确定的结果，以及最终的、确定的结果。

```swift
import SwiftUI
import Speech

class SpeechRecognizer: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    @Published var recognizedText = ""

    func startTranscribing() {
        // ... (请求授权的代码)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.recognizedText = result.bestTranscription.formattedString
            }
            // ...
        }
        
        // ... (配置并启动 AVAudioEngine 来获取麦克风输入) ...
    }
    
    func stopTranscribing() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }
}
```

## 2. `AVFoundation` (AVSpeechSynthesizer)：语音合成 (Text-to-Speech)

`AVSpeechSynthesizer` 是 `AVFoundation` 框架中的一个类，它负责将文本转换为语音并播放出来。

### 核心用法

1.  **创建 `AVSpeechUtterance`**: 这是一个包含了要朗读的文本、以及朗读方式（如语速 `rate`、音调 `pitchMultiplier`、音量 `volume`）的对象。
2.  **选择声音 (`AVSpeechSynthesisVoice`)**: 你可以从系统中可用的声音中，选择一个特定的声音（例如，不同的语言、不同的性别）。
3.  **创建 `AVSpeechSynthesizer`**: 创建一个语音合成器的实例。
4.  **开始朗读**: 调用合成器的 `speak(_:)` 方法，并传入你创建的 `AVSpeechUtterance`。

```swift
import AVFoundation

struct TextToSpeechExample: View {
    let synthesizer = AVSpeechSynthesizer()
    @State private var textToSpeak = "你好，SwiftUI！"

    var body: some View {
        VStack {
            TextEditor(text: $textToSpeak)
            Button("朗读") {
                speak()
            }
        }
    }

    func speak() {
        // 1. 创建 Utterance
        let utterance = AVSpeechUtterance(string: textToSpeak)
        
        // 2. (可选) 选择声音
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        
        // 3. (可选) 设置语速和音调
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.2
        
        // 4. 开始朗读
        synthesizer.speak(utterance)
    }
}
```

## 3. `SoundAnalysis` 框架：声音分析

`SoundAnalysis` 框架 (iOS 15+) 允许你的应用识别出环境中的特定声音。它使用一个内置的 Core ML 模型 (`SoundClassifier.mlmodel`)，可以识别数百种不同的声音类别。

*   **核心用法**: 
    1.  创建一个 `SNAudioStreamAnalyzer`，并为其提供来自麦克风的音频流。
    2.  创建一个 `SNClassifySoundRequest`，并指定你想要识别的声音类型（例如，`SNClassifierIdentifier.version1` 代表使用系统内置的模型）。
    3.  将请求添加到分析器中。
    4.  实现 `SNResultsObserving` 代理协议，在 `request(_:didProduce:)` 方法中接收识别结果（`SNClassificationResult`）。
*   **应用场景**: 
    *   为听障人士开发的应用，在检测到火警、门铃或婴儿哭声时发出提醒。
    *   智能家居应用，在检测到玻璃破碎声时触发安全警报。

## 总结

苹果的语音技术框架为开发者提供了一套完整的、从“听”（语音识别）到“说”（语音合成）再到“理解”（声音分析）的工具链。

*   **语音转文本**: 使用 **`Speech`** 框架，其核心是 `SFSpeechRecognizer` 和 `SFSpeechRecognitionTask`。
*   **文本转语音**: 使用 **`AVFoundation`** 中的 `AVSpeechSynthesizer` 和 `AVSpeechUtterance`。
*   **声音分类**: 使用 **`SoundAnalysis`** 框架，通过 `SNClassifySoundRequest` 来识别环境声音。

这些框架大多在端侧运行，具有高性能和高隐私性的特点。通过将这些语音能力集成到你的应用中，你可以创建出更自然、更易于访问、更具未来感的交互体验。
