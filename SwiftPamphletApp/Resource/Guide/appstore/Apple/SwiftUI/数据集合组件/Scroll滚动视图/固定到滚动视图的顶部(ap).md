# SwiftUI ScrollView：固定视图到顶部 (Pinned Views)

在 `ScrollView` 或 `List` 中，一个常见的需求是让某个视图（通常是 `Section` 的页眉 `header`）在向上滚动时，“固定”或“钉”在滚动视图的顶部，直到该 `Section` 的所有内容都完全滚出屏幕。这种效果被称为“粘性页眉”（Sticky Header）。

SwiftUI 通过 `LazyVStack` 和 `Section` 的组合，为实现这一功能提供了内置的支持。

## 核心用法：`LazyVStack` 与 `Section`

要创建一个带有固定页眉的滚动列表，你需要：

1.  将你的内容放置在一个 `ScrollView` 中。
2.  使用 `LazyVStack` 作为 `ScrollView` 的直接子视图。**必须是 `LazyVStack`**，因为常规的 `VStack` 不支持固定行为。
3.  使用 `Section` 来组织你的内容，并将你希望固定的视图作为 `Section` 的 `header` 参数传入。
4.  (可选) 为 `LazyVStack` 的 `pinnedViews` 参数提供 `.sectionHeaders` 来明确启用该行为（尽管这通常是默认行为）。

```swift
import SwiftUI

struct PinnedHeaderExample: View {
    var body: some View {
        ScrollView {
            // 1. 使用 LazyVStack
            LazyVStack(alignment: .leading, spacing: 10, pinnedViews: [.sectionHeaders]) {
                // 2. 使用 Section 并提供 header
                ForEach(1...5, id: \.self) { sectionIndex in
                    Section(
                        header: 
                            Text("Header for Section \(sectionIndex)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.8))
                                .foregroundColor(.white)
                    ) {
                        // Section 的内容
                        ForEach(1...10, id: \.self) { rowIndex in
                            Text("Row \(rowIndex) in Section \(sectionIndex)")
                                .padding()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PinnedHeaderExample()
}
```

在这个例子中：
*   我们创建了一个包含多个 `Section` 的 `LazyVStack`。
*   每个 `Section` 都有一个自定义的 `header` 视图。
*   `LazyVStack` 的 `pinnedViews` 参数被设置为 `[.sectionHeaders]`。
*   当你运行并滚动这个视图时，你会看到每个 `header` 在其对应的 `Section` 内容滚动时，会“粘”在 `ScrollView` 的顶部。

## 固定页脚 (`.sectionFooters`)

与固定页眉类似，你也可以通过将 `.sectionFooters` 添加到 `pinnedViews` 数组中，来让 `Section` 的 `footer` 固定在滚动视图的底部。

```swift
LazyVStack(pinnedViews: [.sectionHeaders, .sectionFooters]) {
    Section(
        header: Text("Header"),
        footer: Text("Footer").frame(maxWidth: .infinity).background(Color.gray)
    ) {
        // ... content
    }
}
```

## `List` 中的固定页眉

`List` 本身就内置了对固定页眉和页脚的支持，其行为与 `ScrollView` + `LazyVStack` 的组合非常相似。你只需要在 `List` 中使用 `Section` 即可。

```swift
List {
    ForEach(1...5, id: \.self) { sectionIndex in
        Section(header: Text("Header \(sectionIndex)")) {
            ForEach(1...10, id: \.self) { rowIndex in
                Text("Row \(rowIndex)")
            }
        }
    }
}
.listStyle(.plain) // .plain 样式下的固定效果最明显
```

在 `.plain` 列表样式下，`Section` 的 `header` 会自动具有粘性效果。

## 注意事项

*   **必须是 `Lazy` 堆栈**: 只有 `LazyVStack` 和 `LazyHStack` 支持 `pinnedViews` 功能。常规的 `VStack` 和 `HStack` 会一次性加载所有内容，无法实现粘性效果。
*   **`ScrollView` 的直接子视图**: `LazyVStack` 应该作为 `ScrollView` 的直接子视图，以确保它能够正确地计算滚动和固定的位置。
*   **`Section` 是关键**: 固定的行为是 `Section` 的 `header` 和 `footer` 的特性，而不是任意视图的特性。

## 总结

在 SwiftUI 中实现“粘性页眉”或“固定页眉”的效果非常简单，这得益于 `LazyVStack` 和 `Section` 的内置协作。

*   **核心组合**: `ScrollView` + `LazyVStack` + `Section`。
*   **启用方式**: 在 `LazyVStack` 的 `pinnedViews` 参数中包含 `.sectionHeaders`。
*   **`List` 的替代方案**: 对于需要标准列表样式的场景，直接在 `List` 中使用 `Section` 也能自动获得类似的效果（尤其是在 `.plain` 样式下）。

通过这种声明式的方式，你可以轻松地为长列表创建清晰的、具有上下文感的分组标题，极大地提升了列表的可读性和导航效率。
