# iOS/macOS 系统能力：分享扩展 (Share Extension)

分享扩展（Share Extension）是苹果提供的一种强大的应用扩展（App Extension），它允许你的应用出现在系统范围的分享面板（Share Sheet）中。当用户在其他应用（如 Safari、照片、备忘录）中点击“分享”按钮时，他们可以直接选择你的应用，并将内容（如 URL、图片、文本）发送到你的应用中进行处理。

这为你的应用提供了一个强大的入口，让用户可以方便地将来自各处的内容聚合到你的应用中。

## 核心理念：独立进程与数据交换

*   **独立进程**: 分享扩展是在一个**独立于**你的主应用的进程中运行的。这意味着它有自己的内存空间和生命周期。它不能直接访问你主应用中的变量或对象。
*   **数据交换**: 主应用和分享扩展之间的数据交换，通常需要通过共享的资源来完成，最常见的方式是 **App Groups**。

## 创建分享扩展

1.  **添加 Target**: 在你的 Xcode 项目中，选择 File -> New -> Target...，然后选择 “Share Extension”。
2.  **激活 Target**: Xcode 会提示你是否要激活这个新的 Scheme，选择“Activate”。
3.  **文件结构**: Xcode 会为你生成一个新的文件夹，其中包含：
    *   `ShareViewController.swift`: 一个 `UIViewController` 的子类，这是你分享扩展的 UI 和主要逻辑所在。
    *   `MainInterface.storyboard`: 定义了分享扩展的 UI（尽管你也可以完全用代码或 SwiftUI 来构建 UI）。
    *   `Info.plist`: 分享扩展的配置文件。

## 配置 `Info.plist`

`Info.plist` 文件是配置分享扩展行为的关键。你需要修改 `NSExtension` 字典中的 `NSExtensionActivationRule`。

`NSExtensionActivationRule` 定义了你的分享扩展会在**何种类型**的内容被分享时出现。

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>NSExtensionActivationRule</key>
        <string>
            SUBQUERY ( 
                extensionItems, 
                $extensionItem, 
                SUBQUERY ( 
                    $extensionItem.attachments, 
                    $attachment, 
                    ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.url" || 
                    ANY $attachment.registeredTypeIdentifiers UTI-CONFORMS-TO "public.image"
                ).@count == 1 
            ).@count == 1
        </string>
    </dict>
    <key>NSExtensionMainStoryboard</key>
    <string>MainInterface</string>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.share-services</string>
</dict>
```

这个复杂的谓词字符串（Predicate String）的含义是：
*   当分享的内容中，附件（`attachments`）的数量为 1，并且...
*   ...该附件的类型标识符（UTI）符合 `public.url` (URL) **或** `public.image` (图片) 时，激活此分享扩展。

你可以修改这个规则来支持你想要处理的任何数据类型，如 `public.plain-text` (纯文本) 或 `public.file-url` (文件)。

## `ShareViewController` 的核心逻辑

`ShareViewController` 继承自 `SLComposeServiceViewController`（一个旧的、简化的基类）或更底层的 `UIViewController`。它的核心任务是：

1.  **获取分享内容**: 从 `extensionContext` 中提取用户分享的项目。
2.  **呈现 UI**: 显示一个界面，允许用户对分享的内容进行编辑或添加评论。
3.  **处理操作**: 当用户点击“发布”（Post）或“取消”（Cancel）时，执行相应的操作。

```swift
import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // 在这里可以验证用户的输入内容是否有效
        return !contentText.isEmpty
    }

    override func didSelectPost() {
        // 当用户点击“发布”按钮时调用
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        // 根据类型加载数据
        if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
            itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { (url, error) in
                if let shareURL = url as? URL {
                    // 在这里处理分享的 URL
                    // 例如，通过 App Group 的 UserDefaults 保存它
                    print("分享的 URL: \(shareURL)")
                    print("用户评论: \(self.contentText)")
                }
                // 必须调用 completeRequest 来结束扩展的生命周期
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
        }
    }

    override func configurationItems() -> [Any]! {
        // 在这里可以提供一些配置项，显示在分享视图中
        return []
    }
}
```

## App Groups：主应用与扩展的数据共享

由于分享扩展和主应用是两个独立的进程，它们不能直接共享内存。要在它们之间传递数据，你需要使用 **App Groups**。

1.  **启用 App Groups**: 在 Xcode 的 “Signing & Capabilities” 中，为你的**主应用 Target** 和**分享扩展 Target** 同时添加 “App Groups” 能力。
2.  **创建 App Group**: 创建一个唯一的 App Group 标识符（例如 `group.com.myapp.shared`），并确保两个 Target 都勾选了它。
3.  **使用共享资源**: 
    *   **`UserDefaults`**: 使用 `UserDefaults(suiteName: "group.com.myapp.shared")` 来创建一个可以被两者共享的 `UserDefaults` 实例。
    *   **共享文件容器**: 使用 `FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)` 来获取一个共享的沙盒目录 URL，你可以在其中读写文件。

**通用流程**: 
1.  在 `ShareViewController` 中，当用户点击“发布”时，将分享的数据（如 URL 和评论）写入到共享的 `UserDefaults` 或文件中。
2.  在主应用中，监听这些共享数据的变化（例如，在 `AppDelegate` 或 SwiftUI 的 `.onReceive` 中），并在数据更新时，执行相应的操作（如刷新列表、显示新添加的内容）。

## 总结

分享扩展是增强应用集成度和用户粘性的一个重要系统能力。

*   **核心**: 它是一个在独立进程中运行的**应用扩展**，可以出现在系统分享面板中。
*   **配置**: 通过 `Info.plist` 中的 `NSExtensionActivationRule` 来定义它能处理的内容类型。
*   **数据处理**: 在 `ShareViewController` 中，从 `extensionContext` 获取分享的数据。
*   **数据共享**: **必须**通过 **App Groups** 来实现分享扩展与主应用之间的数据交换。

通过实现一个分享扩展，你可以让你的应用成为用户处理和聚合信息流中的一个重要节点，极大地扩展了你的应用的使用场景。
