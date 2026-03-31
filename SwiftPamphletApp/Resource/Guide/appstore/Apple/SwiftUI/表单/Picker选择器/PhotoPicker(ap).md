# SwiftUI 中的 PhotosPicker (iOS 16+)

从 iOS 16 开始，SwiftUI 引入了一个现代、强大且注重隐私的 `PhotosPicker` 视图，用于替代旧有的、基于 `UIKit` 的 `UIImagePickerController`。它为用户提供了一个安全、流畅的方式来从他们的照片库中选择一张或多张图片或视频，而无需向应用授予完整的照片库访问权限。

## 核心概念：解耦与隐私

`PhotosPicker` 的设计核心是**隐私**。它在一个独立于你的应用的进程中运行，这意味着：

1.  **无需请求权限**: 你的应用不需要显式地请求访问照片库的权限。用户可以在一个安全的、由系统提供的界面中进行选择。
2.  **有限访问**: 应用只会接收到用户**明确选择**的那些项目，而无法窥探用户的整个照片库。

`PhotosPicker` 的工作流程是解耦的：

1.  **呈现选择器**: 你在视图中放置一个 `PhotosPicker`，它表现为一个可点击的按钮或标签。
2.  **用户选择**: 用户点击后，系统会呈现一个功能完善的照片选择界面。用户可以在其中浏览、搜索并选择一个或多个项目。
3.  **处理结果**: 当用户完成选择后，`PhotosPicker` 会将其绑定的状态变量更新为一组 `PhotosPickerItem` 对象。你需要异步地从这些 `PhotosPickerItem` 中加载实际的图像数据。

## 基本用法：选择单张照片

选择单张照片的典型流程如下：

```swift
import SwiftUI
import PhotosUI

struct SinglePhotoPickerExample: View {
    // 1. 状态变量存储选择的 PhotosPickerItem
    @State private var selectedItem: PhotosPickerItem?
    // 2. 状态变量存储加载后的图像数据
    @State private var selectedImageData: Data?

    var body: some View {
        VStack(spacing: 20) {
            Text("选择一张照片")
                .font(.headline)
            
            // 3. 显示选择的图片
            if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
            } else {
                Image(systemName: "photo.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .foregroundColor(.gray)
            }
            
            // 4. 创建 PhotosPicker
            PhotosPicker(
                selection: $selectedItem,      // 绑定到 PhotosPickerItem
                matching: .images,             // 只匹配图片
                photoLibrary: .shared()        // 使用共享的照片库
            ) {
                // 这是选择器的标签
                Label("选择照片", systemImage: "photo")
            }
            .buttonStyle(.borderedProminent)
        }
        // 5. 监听 selectedItem 的变化
        .onChange(of: selectedItem) { newItem in
            Task {
                // 6. 异步加载图像数据
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
    }
}

#Preview {
    SinglePhotoPickerExample()
}
```

在这个例子中：
1.  `selectedItem` 用于存储用户选择的 `PhotosPickerItem`。
2.  `selectedImageData` 用于存储从 `PhotosPickerItem` 中异步加载出来的 `Data`。
3.  `PhotosPicker` 被创建，并绑定到 `$selectedItem`。`matching: .images` 参数确保了用户只能选择图片。
4.  `.onChange(of: selectedItem)` 修饰符用于监听用户的选择。当 `selectedItem` 不再是 `nil` 时，意味着用户已经做出了选择。
5.  在 `Task` 中，我们调用 `newItem.loadTransferable(type: Data.self)`。这是一个异步方法，它会加载所选项目的 `Data`。加载完成后，我们更新 `selectedImageData` 状态，从而触发 `Image` 视图的刷新。

## 选择多张照片

选择多张照片的逻辑非常相似，只是需要将绑定的状态变量从单个 `PhotosPickerItem?` 改为 `[PhotosPickerItem]` 数组。

```swift
struct MultiplePhotoPickerExample: View {
    // 1. 绑定到一个数组
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImagesData: [Data] = []

    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    // 显示所有选择的图片
                    ForEach(selectedImagesData, id: \.self) { data in
                        if let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable().scaledToFit().frame(height: 150)
                        }
                    }
                }
            }
            
            // 2. 创建 PhotosPicker，并绑定到数组
            PhotosPicker(selection: $selectedItems, maxSelectionCount: 5, matching: .images) {
                Label("选择最多5张照片", systemImage: "photo.on.rectangle.angled")
            }
        }
        .onChange(of: selectedItems) { newItems in
            selectedImagesData = [] // 清空旧数据
            for item in newItems {
                Task {
                    // 3. 遍历并异步加载每张图片
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        selectedImagesData.append(data)
                    }
                }
            }
        }
    }
}
```

关键变化：
*   `selection` 绑定到了一个 `[PhotosPickerItem]` 数组。
*   `maxSelectionCount` 参数可以限制用户最多能选择多少张照片。
*   在 `.onChange` 中，我们遍历 `newItems` 数组，并为每一个 `item` 启动一个异步加载任务。

## 过滤选择内容 (`matching`)

`matching` 参数允许你精确地过滤用户可以在照片库中看到和选择的内容类型。它接受一个 `PHPickerFilter` 实例。

*   `.images`: 只显示图片（不包括 Live Photos）。
*   `.videos`: 只显示视频。
*   `.livePhotos`: 只显示 Live Photos。
*   `.any(of: [...])`: 组合多个过滤器，例如 `.any(of: [.images, .videos])` 允许用户同时选择图片和视频。

## 总结

`PhotosPicker` 是在现代 SwiftUI 应用中处理图片和视频选择的首选方式。它的主要优点在于：

*   **隐私友好**: 无需请求完整的照片库访问权限，保护了用户隐私。
*   **现代化的 API**: 使用 `async/await` 和 `Transferable` 协议，使得异步加载数据变得非常简洁。
*   **功能强大**: 支持单选、多选、内容过滤，并提供了由系统驱动的、功能完善的选择界面。
*   **简单易用**: 将复杂的照片库交互封装在了一个简单的 SwiftUI 视图中。

通过掌握 `PhotosPicker` 的用法，你可以轻松地为你的应用添加安全、流畅的媒体选择功能。
