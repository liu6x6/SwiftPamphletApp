# macOS SwiftUI 范例：构建一个完整的应用

理论需要通过实践来巩固。本篇将通过一个迷你的、但功能相对完整的 macOS 应用范例，来串联和展示 SwiftUI 在 macOS 开发中的各种核心组件和技术。

我们将构建一个简单的“笔记”应用，它具有以下功能：
*   一个三栏布局的界面。
*   可以查看笔记列表，并按文件夹分类。
*   可以查看和编辑单篇笔记的内容。
*   可以在导航栏和工具栏中执行操作。

## 1. 数据模型

首先，定义我们的核心数据模型。我们需要一个 `Folder` 和一个 `Note`。

```swift
import Foundation

struct Folder: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var notes: [Note]
}

struct Note: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var content: String
}

// 示例数据
@MainActor
class NoteStore: ObservableObject {
    @Published var folders: [Folder] = [
        Folder(name: "工作", notes: [
            Note(title: "Q3 报告", content: "这是第三季度的报告内容..."),
            Note(title: "会议纪要", content: "关于项目 A 的讨论...")
        ]),
        Folder(name: "生活", notes: [
            Note(title: "购物清单", content: "牛奶、鸡蛋、面包")
        ])
    ]
}
```

我们创建一个 `NoteStore` 作为 `ObservableObject`，用于在整个应用中共享和修改我们的数据。

## 2. 主应用入口与三栏布局

我们使用 `NavigationSplitView` 来构建应用的顶级 UI 结构。

```swift
import SwiftUI

@main
struct NotesApp: App {
    @StateObject private var store = NoteStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store) // 将数据模型注入到环境中
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: NoteStore
    @State private var selectedFolderID: Folder.ID?
    @State private var selectedNoteID: Note.ID?

    var body: some View {
        NavigationSplitView {
            // 侧边栏：文件夹列表
            List(store.folders, selection: $selectedFolderID) { folder in
                Text(folder.name).tag(folder.id)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } content: {
            // 主内容：笔记列表
            if let folder = store.folders.first(where: { $0.id == selectedFolderID }) {
                List(folder.notes, selection: $selectedNoteID) { note in
                    Text(note.title).tag(note.id)
                }
            } else {
                Text("请选择一个文件夹")
            }
        } detail: {
            // 详情：笔记编辑器
            if let folderIndex = store.folders.firstIndex(where: { $0.id == selectedFolderID }),
               let noteIndex = store.folders[folderIndex].notes.firstIndex(where: { $0.id == selectedNoteID }) {
                
                // 使用 Binding 来直接修改 store 中的数据
                let noteBinding = $store.folders[folderIndex].notes[noteIndex]
                NoteEditorView(note: noteBinding)
                
            } else {
                Text("请选择一篇笔记")
            }
        }
    }
}
```

**代码解析**:
*   **`@main`**: 我们在 `NotesApp` 中创建 `NoteStore` 的实例，并使用 `@StateObject` 来确保其生命周期与应用相同。然后通过 `.environmentObject()` 将其注入到整个视图层级。
*   **`NavigationSplitView`**: 创建了一个三栏布局。
*   **`selection` 绑定**: 我们使用 `@State` 变量 `selectedFolderID` 和 `selectedNoteID` 来分别追踪侧边栏和内容栏的选择。`List` 的 `selection` 参数会自动更新这些状态。
*   **数据传递**: `content` 视图和 `detail` 视图会根据 `selectedFolderID` 和 `selectedNoteID` 来从 `store` 中查找并显示相应的数据。
*   **`Binding`**: 在 `detail` 视图中，我们创建了一个到 `store` 中具体 `Note` 实例的**绑定** (`$store.folders[...].notes[...]`)。这使得 `NoteEditorView` 可以直接修改原始数据源。

## 3. 笔记编辑器视图

`NoteEditorView` 接收一个到 `Note` 的绑定，并使用 `TextField` 和 `TextEditor` 来显示和编辑内容。

```swift
struct NoteEditorView: View {
    @Binding var note: Note

    var body: some View {
        VStack {
            TextField("标题", text: $note.title)
                .font(.largeTitle)
                .textFieldStyle(.plain)
                .padding(.horizontal)
            
            Divider()
            
            TextEditor(text: $note.content)
                .padding()
        }
        .toolbar {
            // 添加工具栏按钮
            ToolbarItemGroup {
                Button("分享", systemImage: "square.and.arrow.up") { /* ... */ }
                Button("删除", systemImage: "trash", role: .destructive) { /* ... */ }
            }
        }
    }
}
```

因为 `note` 是一个 `@Binding`，所以当用户在 `TextField` 或 `TextEditor` 中输入时，`NoteStore` 中的原始数据会**立即被更新**，并且所有依赖该数据的视图（例如，笔记列表中的标题）也会自动刷新。

## 4. 菜单栏命令

在 macOS 上，我们还可以通过 `.commands` 修饰符来向系统菜单栏添加自定义的命令。

```swift
@main
struct NotesApp: App {
    @StateObject private var store = NoteStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .commands { // 添加自定义菜单命令
            CommandMenu("笔记") {
                Button("新建笔记") {
                    // 在这里实现新建笔记的逻辑
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
}
```

## 总结

这个简单的范例展示了构建一个现代 macOS SwiftUI 应用的核心要素：

*   **`App` 协议与 `@main`**: 作为应用的入口点。
*   **`ObservableObject`**: 用于创建和管理应用的核心数据模型（单一数据源）。
*   **`@StateObject` & `@EnvironmentObject`**: 用于在视图层级中创建、持有和传递共享的数据模型。
*   **`NavigationSplitView`**: 构建桌面级应用标准的三栏式布局。
*   **数据驱动的选择**: 使用 `List` 的 `selection` 参数来驱动 `content` 和 `detail` 视图的内容更新。
*   **`@Binding`**: 允许详情视图直接修改数据源，实现双向数据流。
*   **`.toolbar`**: 以一种声明式的方式向导航栏添加操作按钮。
*   **`.commands`**: 与 macOS 的菜单栏系统进行集成。

通过组合这些核心组件和技术，你可以构建出结构清晰、数据流明确、具有平台原生体验的强大 macOS 应用程序。
