# iOS 图片处理基础

在 iOS 开发中，图片处理是一个非常常见的需求，涉及到从简单的图片展示、压缩、裁剪，到复杂的滤镜应用和底层像素操作。Apple 为此提供了从高层到低层的一系列框架。

## 1. 核心框架概览

*   **UIKit / AppKit (`UIImage` / `NSImage`)**：最高层的面向对象框架。适用于绝大多数日常的图片展示、简单的缩放和格式转换（如 JPEG/PNG 互转）。
*   **Core Image (`CIImage`, `CIFilter`)**：专注于图像的实时滤镜处理和分析（如面部识别、条形码检测）。它底层利用 GPU 加速，性能极高。
*   **Core Graphics (`CGImage`)**：基于 C 语言的底层 2D 绘图引擎。`UIImage` 的底层其实就是一个 `CGImage`。它适用于底层的像素级操作、位图上下文渲染和 PDF 处理。
*   **Image I/O**：专门用于高效地读取和写入图片数据格式。它能在不把整张图片解压到内存的情况下，获取图片的尺寸、EXIF 元数据（地理位置、相机型号等）。
*   **Metal / MetalPerformanceShaders**：直接与 GPU 交互的最底层框架，用于开发自定义的高性能渲染管线或极其复杂的图像算法。

## 2. UIImage 基础操作

### 格式转换与压缩
将 `UIImage` 转换为 `Data` 以便上传或保存：

```swift
let image = UIImage(named: "avatar")!

// 转换为 PNG 数据 (无损)
let pngData = image.pngData()

// 转换为 JPEG 数据 (有损压缩，0.0 到 1.0 表示质量)
let jpegData = image.jpegData(compressionQuality: 0.8)
```

### 使用 UIGraphicsImageRenderer 裁剪/缩放 (推荐)
在 iOS 10 引入了基于闭包的 API，它比旧的 `UIGraphicsBeginImageContext` 更加内存安全，且完美支持设备的屏幕缩放因子 (@2x, @3x)。

```swift
func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = UIScreen.main.scale
    
    let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
    let resizedImage = renderer.image { _ in
        // 在指定的上下文中重绘原图
        image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
    return resizedImage
}
```

## 3. Core Image：添加滤镜

Core Image 使用 `CIFilter`，它内置了上百种滤镜（如高斯模糊、色彩反转、复古效果等）。

```swift
import CoreImage
import CoreImage.CIFilterBuiltins

func applySepiaFilter(to image: UIImage) -> UIImage? {
    // 1. 获取底层 CIImage
    guard let ciImage = image.ciImage ?? CIImage(image: image) else { return nil }
    
    // 2. 创建一个基于 iOS 13+ 强类型 API 的滤镜
    let filter = CIFilter.sepiaTone()
    filter.inputImage = ciImage
    filter.intensity = 0.8 // 调整强度
    
    // 3. 获取输出图像
    guard let outputCIImage = filter.outputImage else { return nil }
    
    // 4. 将 CIImage 转回 UIImage
    // 注意：直接使用 UIImage(ciImage:) 渲染可能会比较慢，推荐使用 CIContext 显式渲染
    let context = CIContext(options: nil)
    if let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) {
        return UIImage(cgImage: cgImage)
    }
    return nil
}
```

## 4. Image I/O：降低内存占用的技巧 (Downsampling)

如果用户相册里有一张 4K 分辨率 (比如 10MB 大小) 的照片，你只需要在 UI 上显示一个 100x100 的缩略图。如果你直接使用 `UIImage(data:)`，系统会把整张 4K 图片解压到内存中，瞬间吃掉上百兆内存，导致 OOM (Out Of Memory) 崩溃。

**最佳实践：使用 Image I/O 进行下采样 (Downsampling)**

```swift
import ImageIO

func downsample(imageAt imageURL: URL, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let imageSource = CGImageSourceCreateWithURL(imageURL as CFURL, imageSourceOptions) else {
        return nil
    }
    
    let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
    
    let downsampleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true, // 始终创建缩略图
        kCGImageSourceShouldCacheImmediately: true,         // 解压后立即缓存
        kCGImageSourceCreateThumbnailWithTransform: true,   // 包含方向变换
        kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels // 限制最大像素
    ] as CFDictionary
    
    guard let downsampledCGImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
        return nil
    }
    
    return UIImage(cgImage: downsampledCGImage)
}
```
*这套方案直接在读取文件时限制了解压尺寸，是处理高清大图的最佳选择。*