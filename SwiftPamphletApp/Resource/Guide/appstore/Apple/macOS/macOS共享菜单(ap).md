# macOS 上的共享菜单

在 macOS 上，共享菜单（Share Menu）是一个系统级的、可扩展的功能，它允许用户从任何支持的应用中，将内容（如文本、图片、文件、URL）方便地分享到其他应用或服务。

与 iOS 上的分享面板（Share Sheet）类似，macOS 的共享菜单为你的应用提供了一个强大的集成点，让你的应用可以作为内容的“目的地”出现在系统的各个角落。

## SwiftUI 中的 `ShareLink`

从 macOS 13 和 iOS 16 开始，在 SwiftUI 中触发共享菜单的最现代、最简单的方式是使用 `ShareLink`。

`ShareLink` 会自动渲染为一个标准的“共享”按钮（一个带有向上箭头的方框）。当用户点击它时，系统会弹出一个标准的 `NSSharingServicePicker`（共享服务选择器）菜单，其中列出了所有能够处理你所提供内容的应用和服务。

```swift
import SwiftUI

struct MacOSShareLinkExample: View {
    let urlToShare = URL(string: "https://developer.apple.com/xcode/")!

    var body: some View {
        VStack {
            // ShareLink 会自动创建一个标准的共享按钮
            ShareLink(item: urlToShare) {
                // 你可以提供一个自定义的标签
                Label("分享 Xcode 链接", systemImage: "square.and.arrow.up")
            }
        }
        .padding()
    }
}

#Preview {
    MacOSShareLinkExample()
}
```

`ShareLink` 的强大之处在于它与 `Transferable` 协议的集成。你只需要提供一个遵循 `Transferable` 的数据项（如 `String`, `URL`, `Image` 或你自己的自定义类型），`ShareLink` 就会自动处理如何将其呈现给共享服务。

## AppKit 中的 `NSSharingServicePicker`

如果你在使用 AppKit 或者需要对共享菜单进行更底层的控制，你可以直接使用 `NSSharingServicePicker`。

`NSSharingServicePicker` 是一个可以从指定项目数组中选择一个 `NSSharingService` 的视图控制器。

```swift
import AppKit

class ShareViewController: NSViewController {
    @IBAction func shareButtonClicked(_ sender: NSButton) {
        let itemsToShare = ["Hello, macOS!", NSImage(named: "MyImage")]
        
        // 1. 创建一个 NSSharingServicePicker
        let picker = NSSharingServicePicker(items: itemsToShare)
        
        // 2. (可选) 设置代理来监听选择和完成
        picker.delegate = self
        
        // 3. 在触发按钮的相对位置显示选择器
        picker.show(relativeTo: .zero, of: sender, preferredEdge: .minY)
    }
}

extension ShareViewController: NSSharingServicePickerDelegate {
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, didChoose service: NSSharingService?) {
        // 当用户从菜单中选择了一个服务时调用
        // 如果用户没有选择任何服务就关闭了菜单，service 会是 nil
        if let service = service {
            print("用户选择了服务: \(service.title)")
            // 服务会自动执行，你通常不需要在这里做什么
        }
    }
}
```

## 创建自定义的共享服务 (`NSSharingService`)

你的应用不仅可以**使用**共享菜单，还可以**向**共享菜单中添加自己的服务，让其他应用可以把内容分享到你的应用里。这通常通过创建一个“分享扩展”（Share Extension）来实现。

然而，对于一些简单的场景，你也可以通过在 `AppDelegate` 中注册一个自定义的 `NSSharingService` 来实现。

1.  **在 `Info.plist` 中声明服务**: 你需要在 `Info.plist` 中添加 `NSServices` 数组，并为你的服务定义名称、菜单项标题、它可以处理的数据类型等。

2.  **在 `AppDelegate` 中注册服务提供者**: 

    ```swift
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.servicesProvider = self
    }
    ```

3.  **实现服务方法**: 在你的服务提供者对象（例如 `AppDelegate`）中，实现一个与你在 `Info.plist` 中定义的方法名相匹配的方法。这个方法会接收被分享的内容。

    ```swift
    @objc func handleSharedText(_ pboard: NSPasteboard, userData: String?, error: NSErrorPointer) {
        guard let str = pboard.string(forType: .string) else {
            return
        }
        
        // 在这里处理接收到的字符串
        print("通过共享服务接收到文本: \(str)")
    }
    ```

这种方式比创建分享扩展更轻量，但功能也更受限，主要适用于处理简单的文本或文件分享。

## 总结

macOS 的共享菜单是一个强大的系统集成点。

*   **触发分享 (SwiftUI)**: **`ShareLink`** 是最现代、最简单的方式。它利用 `Transferable` 协议，可以轻松地分享各种类型的数据。

*   **触发分享 (AppKit)**: 使用 **`NSSharingServicePicker`** 可以更精确地控制共享菜单的显示位置和行为。

*   **接收分享**: 
    *   **分享扩展 (Share Extension)**: 是功能最完整、最强大的方式，它运行在一个独立的进程中，并拥有自己的 UI。
    *   **自定义 `NSSharingService`**: 一种更轻量级的方式，适用于在主应用中直接处理接收到的简单数据。

通过正确地集成共享菜单，你可以让你的应用更好地融入 macOS 生态系统，为用户提供更连贯、更便捷的数据交换体验。
