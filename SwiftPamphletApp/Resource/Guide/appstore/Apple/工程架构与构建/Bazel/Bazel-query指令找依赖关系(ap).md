# 使用 Bazel Query 分析依赖关系

在大型项目中，随着模块数量的增长，理解和管理模块之间的依赖关系变得至关重要。混乱的依赖关系（如循环依赖、不必要的传递性依赖）会严重影响项目的可维护性、编译速度和架构的清晰度。Bazel 提供了强大的查询工具 `bazel query`，允许开发者对项目的依赖图（Dependency Graph）进行精确、高效的分析。

## `bazel query` 简介

`bazel query` 是一个用于查询和分析构建目标的命令行工具。它接收一个“查询表达式”作为输入，并输出满足该表达式的目标（target）列表。通过组合不同的查询函数，你可以回答关于依赖关系的各种复杂问题。

### 基本语法

```bash
bazel query "<查询表达式>"
```

查询表达式通常由**函数**和**目标**组成。

## 常用查询函数

### 1. `deps(x)`: 查找目标的传递性依赖

`deps(x)` 会返回目标 `x` 的所有传递性依赖项（包括 `x` 自身）。这是最常用的查询函数之一。

**示例**: 查找目标 `//main:app` 的所有依赖。

```bash
bazel query "deps(//main:app)"
```

你还可以指定一个深度参数，来限制查询的层级。

**示例**: 只查找 `//main:app` 的直接依赖（深度为 1）。

```bash
bazel query "deps(//main:app, 1)"
```

### 2. `rdeps(u, x)`: 查找反向依赖

`rdeps(u, x)` (reverse dependencies) 会在“宇宙” `u` 的范围内，查找所有依赖于目标 `x` 的目标。这对于分析修改一个底层库会影响到哪些上层模块非常有用。

**示例**: 在整个项目中 (`//...`)，查找有哪些目标依赖于 `//common/network:api`。

```bash
bazel query "rdeps(//..., //common/network:api)"
```

**示例**: 只查找直接依赖于 `//common/network:api` 的目标。

```bash
bazel query "rdeps(//..., //common/network:api, 1)"
```

### 3. `somepath(x, y)`: 查找两个目标之间的依赖路径

`somepath(x, y)` 用于查找从目标 `x` 到目标 `y` 的任意一条依赖路径。这对于调试“为什么我的模块 A 会意外地依赖于模块 C？”这类问题极其有用。

**示例**: 查找从主应用 `//main:app` 到某个具体实现 `//feature/login:impl` 之间的依赖路径。

```bash
bazel query "somepath(//main:app, //feature/login:impl)"
```

如果存在路径，`query` 会输出构成该路径的一系列目标。

### 4. `allpaths(x, y)`: 查找所有依赖路径

与 `somepath` 类似，但它会返回从 `x` 到 `y` 的**所有**依赖路径。

### 5. `kind(pattern, x)`: 按规则类型过滤

`kind(rule, expression)` 用于从一个查询表达式的结果中，筛选出特定规则类型（如 `swift_library`, `ios_application`）的目标。

**示例**: 查找 `//main:app` 的所有依赖中，哪些是 `swift_library`。

```bash
bazel query "kind(swift_library, deps(//main:app))"
```

### 6. 集合操作符: `intersect`, `union`, `except`

你可以像操作集合一样，对查询结果进行交集、并集和差集运算。

*   `intersect` (或 `^`): 交集
*   `union` (或 `+`): 并集
*   `except` (或 `-`): 差集

**示例**: 查找同时被 `//app:a` 和 `//app:b` 依赖的目标。

```bash
bazel query "deps(//app:a) intersect deps(//app:b)"
```

## 输出格式

默认情况下，`bazel query` 只输出目标的标签列表。但你可以通过 `--output` 标志来改变输出格式，以获取更丰富的信息。

*   `--output=graph`: 以 Graphviz 的 `.dot` 格式输出依赖图。你可以将这个结果导入到 Graphviz 或其他可视化工具中，生成直观的依赖关系图。
*   `--output=xml`: 以 XML 格式输出，包含了每个目标的详细信息（如规则类型、源文件、依赖项等）。
*   `--output=build`: 以类似 `BUILD` 文件的格式输出。

### 示例：生成可视化依赖图

1.  **生成 `.dot` 文件**:

    ```bash
    bazel query "deps(//main:app)" --output=graph > app_deps.dot
    ```

2.  **使用 Graphviz 转换为图片** (需要先安装 Graphviz: `brew install graphviz`):

    ```bash
    dot -Tpng app_deps.dot -o app_deps.png
    ```

这样，你就可以得到一张清晰的 `app_deps.png` 依赖图图片。

## 实际应用场景

*   **分析不必要的依赖**: 定期运行 `bazel query "deps(//my:target)"` 并审查其输出，可以发现是否引入了非预期的传递性依赖。
*   **评估修改成本**: 在修改一个底层核心库之前，运行 `bazel query "rdeps(//..., //path/to/core:lib)"` 来查看它会影响到多少上层模块，从而评估修改和测试的范围。
*   **调试循环依赖**: 如果 Bazel 在构建时报告了循环依赖，使用 `somepath` 或 `allpaths` 可以快速地定位到造成循环的具体路径。
*   **架构治理**: 编写脚本，定期运行一系列 `query` 命令，检查项目的依赖关系是否符合预设的架构规则（例如，“Feature 层不能直接依赖另一个 Feature 层，必须通过公共的 Service 层”）。

## 总结

`bazel query` 是 Bazel 工具链中一个极其强大的静态分析工具。它为开发者提供了一双“透视眼”，能够清晰地洞察复杂项目的依赖关系网络。

熟练掌握 `deps`, `rdeps`, `somepath` 等核心查询函数，并学会利用不同的输出格式（特别是 `graph`），是管理大型模块化项目、维护清晰架构和提升构建效率的关键技能。
