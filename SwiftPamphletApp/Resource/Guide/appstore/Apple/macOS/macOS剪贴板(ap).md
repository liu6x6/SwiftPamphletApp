# macOS 与 iOS 中的剪贴板操作

剪贴板（Pasteboard）是操作系统提供的一个用于在应用内部或应用之间临时共享数据的标准机制。用户通过“拷贝”（Copy）命令将数据放入剪贴板，然后通过“粘贴”（Paste）命令将数据取出。在苹果生态中，`UIPasteboard` (iOS) 和 `NSPasteboard` (macOS) 是与剪贴板交互的核心 API。

## 核心概念

*   **剪贴板实例**: 
    *   在 iOS 上，通过 `UIPasteboard.general` 获取系统范围的通用剪贴板。
    *   在 macOS 上，通过 `NSPasteboard.general` 获取通用剪贴板。
*   **数据类型 (UTI)**: 剪贴板可以同时存储**多种格式**的同一份数据。例如，当你从一个富文本编辑器中拷贝一段文字时，剪贴板中可能同时包含了该文本的富文本（RTF）格式、纯文本（Plain Text）格式，甚至 HTML 格式。这使得不同的应用可以根据自己的能力，选择性地读取最适合自己的数据格式。这些格式由统一类型标识符（Uniform Type Identifier, UTI）来定义。
*   **`NSItemProvider`**: 这是在现代 iOS/macOS 开发中，用于处理跨应用数据传输（包括剪贴板、拖放、分享等）的标准化对象。它能够异步地、按需地提供数据。

## 写入数据到剪贴板

### 1. 写入简单文本

这是最常见的操作。

**UIKit (iOS)**
```swift
import UIKit

func copyTextToClipboard(text: String) {
    UIPasteboard.general.string = text
}
```

**AppKit (macOS)**
```swift
import AppKit

func copyTextToClipboard(text: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents() // 清空剪贴板
    pasteboard.setString(text, forType: .string)
}
```

### 2. 写入图片

**UIKit (iOS)**
```swift
func copyImageToClipboard(image: UIImage) {
    UIPasteboard.general.image = image
}
```

**AppKit (macOS)**
```swift
func copyImageToClipboard(image: NSImage) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.writeObjects([image])
}
```

### 3. 写入多种数据类型

你可以一次性向剪贴板中写入多种表示方式。

**UIKit (iOS)**
```swift
// 同时提供纯文本和富文本
UIPasteboard.general.items = [
    ["public.plain-text": "Hello"],
    ["public.rtf": rtfData] // 假设 rtfData 是富文本的 Data
]
```

## 从剪贴板读取数据

### 1. 读取简单文本

**UIKit (iOS)**
```swift
func readTextFromClipboard() -> String? {
    if UIPasteboard.general.hasStrings {
        return UIPasteboard.general.string
    }
    return nil
}
```

**AppKit (macOS)**
```swift
func readTextFromClipboard() -> String? {
    return NSPasteboard.general.string(forType: .string)
}
```

### 2. 读取图片

**UIKit (iOS)**
```swift
func readImageFromClipboard() -> UIImage? {
    if UIPasteboard.general.hasImages {
        return UIPasteboard.general.image
    }
    return nil
}
```

**AppKit (macOS)**
```swift
func readImageFromClipboard() -> NSImage? {
    if let image = NSImage(pasteboard: NSPasteboard.general) {
        return image
    }
    return nil
}
```

## SwiftUI 中的剪贴板操作

SwiftUI 本身没有提供一个直接的、跨平台的剪贴板 API，你仍然需要使用特定平台的 `UIPasteboard` 或 `NSPasteboard`。最佳实践是将其封装在一个辅助函数或服务类中。

```swift
import SwiftUI

struct ClipboardManager {
    static func copy(text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
    
    static func paste() -> String? {
        #if os(iOS)
        return UIPasteboard.general.string
        #elseif os(macOS)
        return NSPasteboard.general.string(forType: .string)
        #endif
    }
}

// 在 SwiftUI 视图中使用
struct ClipboardExampleView: View {
    @State private var text = ""

    var body: some View {
        VStack {
            TextField("输入要拷贝的文本", text: $text)
            Button("拷贝") {
                ClipboardManager.copy(text: self.text)
            }
            Button("粘贴") {
                if let pastedText = ClipboardManager.paste() {
                    self.text = pastedText
                }
            }
        }
    }
}
```

## 隐私与安全 (iOS 14+)

从 iOS 14 开始，为了保护用户隐私，当你的应用**首次**尝试访问剪贴板内容时，系统会在屏幕顶部显示一个透明的横幅，通知用户“XXX pasted from YYY”。

从 iOS 16 开始，这个行为变得更加严格。每次你的应用尝试**主动**读取剪贴板时，系统都会弹出一个对话框，请求用户授权“允许粘贴”或“不允许粘贴”。

为了避免频繁地打扰用户，你应该：
*   **使用 `UIMenuController` 或 `UIEditMenuInteraction`**: 当用户长按一个 `TextField` 并**主动**选择“粘贴”菜单时，你的应用可以直接访问剪贴板而**不会**触发授权弹窗。
*   **提供明确的“粘贴”按钮**: 让用户清楚地知道，点击这个按钮将会从剪贴板中读取内容。

## 总结

剪贴板是应用间数据交换的基础设施。

*   **核心 API**: `UIPasteboard` (iOS) 和 `NSPasteboard` (macOS)。
*   **数据格式**: 支持通过 UTI 存储多种数据表示。
*   **SwiftUI 实践**: 将平台特定的 API 封装在一个统一的辅助类或函数中，以便在跨平台代码中调用。
*   **隐私**: 注意 iOS 14+ 对剪贴板访问的隐私保护机制，避免在用户不知情的情况下自动读取剪贴板。

通过正确地使用剪贴板 API，你可以为你的应用提供符合用户习惯的、流畅的复制和粘贴体验。
