# Bazel 构建系统简介 (iOS 视角)

在 iOS 领域，除了 Xcode 自带的 `Xcode Build System`（基于 `.pbxproj`）以及官方的 `Swift Package Manager (SPM)`，在许多**超大型互联网公司**（如 Google、Uber、Lyft、Tinder、国内的大厂）中，**Bazel** 往往是构建整个移动端工程的终极武器。

## 1. 什么是 Bazel？

Bazel 是由 Google 开源的、支持多语言、跨平台的工业级构建工具。它的前身是 Google 内部使用了十几年的 Blaze 构建系统。

## 2. 为什么大厂 iOS 团队要抛弃 Xcode 构建转用 Bazel？

如果一个 iOS 工程只有几十万行代码，使用 CocoaPods + Xcode 完全够用。但当代码量达到**数百万甚至上千万行**，模块多达数百个时，传统的构建方式会面临毁灭性的问题。Bazel 主要是为了解决以下痛点：

### 痛点 A：构建速度极慢
在传统方式下，清理缓存后一次全量编译可能需要 30 分钟甚至 1 小时以上，极大浪费开发者的生命。
**Bazel 的解决方式**：
*   **增量编译的极致精确**：Bazel 要求极其严格地声明每一个模块的依赖关系（Inputs & Outputs）。它不仅可以缓存本地构建过的产物，还能支持**远程缓存 (Remote Caching)**。
*   如果你的同事（或 CI 服务器）几分钟前刚刚编译过某个模块的某个版本，Bazel 会直接从远程服务器下载那个模块的二进制 `.a` 或 `.o` 文件，跳过你本地的编译过程。全量编译时间可缩短至几分钟。

### 痛点 B：Xcode 工程文件 (`.pbxproj`) 冲突黑洞
几百人在同一个仓库开发，合并代码时 `project.pbxproj` 的冲突简直是噩梦。
**Bazel 的解决方式**：
*   **配置即代码 (Configuration as Code)**：Bazel 使用简单的文本文件 `BUILD` (基于类似于 Python 的 Starlark 语言) 来描述目标和依赖。
*   配合开源工具（如 `rules_xcodeproj` 或 `Tulsi`），开发者可以动态地、一键从 `BUILD` 文件**实时生成**没有任何冲突的临时 `.xcodeproj` 文件用来开发。`.xcodeproj` 变成了一个一次性的消耗品，不再提交到 Git 仓库中。

### 痛点 C：跨平台构建的不统一
大厂通常有 iOS、Android、后端（Go/Java/C++）多个团队。
**Bazel 的解决方式**：
*   一套构建系统统治一切。用同样的方法编译 iOS App、打 Android APK 或是构建后端的 Docker 镜像。

## 3. Bazel 在 iOS 中的核心概念

*   **Workspace (工作区)**：工程的根目录，包含一个 `WORKSPACE` 文件，定义了外部依赖（比如需要引入 Apple 编译规则库 `rules_apple` 和 Swift 编译规则库 `rules_swift`）。
*   **BUILD 文件**：分布在每个模块目录下，定义了该目录可以构建出什么（Target）。
*   **Rules (规则)**：决定如何编译。例如 `swift_library` (编译一组 Swift 文件)、`apple_framework`、`ios_application` (将编译结果打包成 .app 并签名)。

```starlark
# 一个极简的 BUILD 文件示例
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "MyFeature",
    srcs = glob(["Sources/**/*.swift"]),
    deps = [
        "//NetworkModule:NetworkLibrary",
    ],
    visibility = ["//visibility:public"],
)
```

## 4. 采用 Bazel 的代价

Bazel 不是银弹，它的引入成本极其高昂：
1. **学习曲线陡峭**：你需要学习 Starlark 语言，理解 Bazel 沙盒机制，并深入了解 Apple 的底层编译和签名链路。
2. **打破生态**：CocoaPods 上的许多老旧第三方库不是为 Bazel 设计的，你需要为它们手动编写或转换 `BUILD` 文件。
3. **专职团队维护**：通常需要一个专门的“基础架构 / 效能工程”团队来维护这套构建管线。中小型团队切勿盲目跟风。