# SwiftUI 中的字体选择器 (Font Picker)

在 SwiftUI 中，虽然 Apple 为颜色、日期和照片等提供了原生的 `ColorPicker`、`DatePicker` 和 `PhotosPicker` 等组件，但**截至目前（iOS 17/macOS 14），SwiftUI 并没有提供一个直接开箱即用的原生跨平台 `FontPicker` 组件**。

不过，我们完全可以通过与其他框架结合，在各个平台上实现字体选择的功能。

## 1. iOS 中的替代方案：封装 UIFontPickerViewController

在 iOS 开发中，标准的做法是使用 UIKit 提供的 `UIFontPickerViewController`。我们可以通过 `UIViewControllerRepresentable` 协议将其桥接到 SwiftUI 中。

### 实现步骤

首先，创建一个结构体来封装 `UIFontPickerViewController`：

```swift
import SwiftUI
import UIKit

struct FontPicker: UIViewControllerRepresentable {
    @Binding var selectedFont: UIFont?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIFontPickerViewController {
        let configuration = UIFontPickerViewController.Configuration()
        configuration.includeFaces = true // 包含不同的字重和样式
        
        let picker = UIFontPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIFontPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIFontPickerViewControllerDelegate {
        var parent: FontPicker

        init(_ parent: FontPicker) {
            self.parent = parent
        }

        func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
            guard let descriptor = viewController.selectedFontDescriptor else { return }
            parent.selectedFont = UIFont(descriptor: descriptor, size: UIFont.labelFontSize)
            parent.presentationMode.wrappedValue.dismiss()
        }

        func fontPickerViewControllerDidCancel(_ viewController: UIFontPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
```

### 在 SwiftUI 中使用

封装完成后，你可以使用 `.sheet` 或 `.popover` 来展示这个字体选择器：

```swift
struct FontPickerExampleView: View {
    @State private var showingFontPicker = false
    @State private var selectedFont: UIFont?

    var body: some View {
        VStack(spacing: 20) {
            Text("这是一段测试文字，用于展示选中的字体效果。")
                .font(selectedFont != nil ? Font(selectedFont!) : .body)
                .padding()

            Button("选择字体") {
                showingFontPicker = true
            }
            .buttonStyle(.borderedProminent)
            .sheet(isPresented: $showingFontPicker) {
                FontPicker(selectedFont: $selectedFont)
            }
            
            if let fontName = selectedFont?.fontName {
                Text("当前选中字体: \(fontName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

## 2. macOS 中的替代方案：使用 NSFontManager 和 NSFontPanel

在 macOS 上，字体管理通常通过 `NSFontManager` 和 `NSFontPanel` 实现。桥接方式与 iOS 类似，但需要使用 `NSViewRepresentable` 或直接与 `AppKit` 交互。

## 3. SwiftUI 原生的字体定制修饰符

虽然没有直接的弹窗组件，但 SwiftUI 提供了丰富的修饰符来让用户“选择”或调整字体样式（通常可以通过自定义 UI 配合这些修饰符来实现类似 Picker 的效果）：

*   `.font(.system(size: 20, weight: .bold, design: .serif))`：指定系统字体的属性。
*   `.fontDesign(.monospaced)`：(iOS 16+) 快速切换字体设计样式（如圆体、等宽体、衬线体）。
*   `.fontWeight(.heavy)`：调整字重。
*   `.fontWidth(.expanded)`：(iOS 16+) 调整字体宽度（如压缩、展开）。

## 总结

虽然缺少原生的 `FontPicker` 视图，但借助强大的平台互通能力（`UIViewControllerRepresentable` 和 `NSViewControllerRepresentable`），在 SwiftUI 应用中集成系统级的高级字体选择器并不困难。在实现时，请注意处理好不同平台的特定 API (UIKit vs AppKit)。
