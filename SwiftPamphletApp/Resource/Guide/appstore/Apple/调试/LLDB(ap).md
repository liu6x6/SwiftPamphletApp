# iOS/macOS 调试：LLDB 调试器

LLDB 是一个强大、现代化的命令行调试器，它是 LLVM 项目的一部分，并且是 Xcode 中内置的默认调试工具。对于任何 iOS 或 macOS 开发者来说，熟练掌握 LLDB 都是一项能够极大地提升调试效率、深入理解代码运行状态的核心技能。

当你设置一个断点，并在 Xcode 中运行应用时，一旦程序执行到断点处，它就会暂停，然后你会在 Xcode 的调试控制台中看到 `(lldb)` 提示符。从这里开始，你就进入了 LLDB 的世界。

## 常用 LLDB 命令

以下是一些最常用、最实用的 LLDB 命令。

### 1. `print` (或 `p`)

`print` 命令用于打印一个变量或表达式的值。它会执行你输入的代码，并显示其结果。

```lldb
(lldb) p myVariable
(lldb) print self.view.frame
```

### 2. `po` (Print Object)

`po` 是 `expression -O --` 的别名，它专门用于打印一个**对象**的描述（调用其 `description` 或 `debugDescription` 方法）。这是调试中最常用的命令，因为它通常能提供比 `print` 更具可读性的输出。

```lldb
(lldb) po myViewController
<MyViewController: 0x7f8c1d82a3b0>

(lldb) po myString
"Hello, World!"

(lldb) po myView.backgroundColor
<UIDynamicSystemColor: 0x600001f0d9c0; name = systemBackgroundColor>
```

### 3. `expression` (或 `e`)

`expression` 是一个功能更强大的命令，它允许你执行几乎任意的 Swift 或 Objective-C 代码，甚至可以改变程序的状态。

```lldb
# 改变变量的值
(lldb) expression myVariable = 10

# 调用一个方法
(lldb) expression self.myFunction()

# 创建一个新的 UI 元素并添加到视图上 (在 UI 调试中非常有用)
(lldb) expression let newView = UIView(frame: .zero); self.view.addSubview(newView)
```

### 4. 控制程序流程

*   **`continue`** (或 `c`): 继续执行程序，直到遇到下一个断点或程序结束。
*   **`next`** (或 `n`): 执行**下一行**代码，但**不会**进入函数调用内部（会直接执行完函数并停在函数调用的下一行）。
*   **`step`** (或 `s`): 执行**下一步**，如果当前行是一个函数调用，它会**进入**该函数内部的第一行。
*   **`finish`**: 继续执行，直到当前函数返回，并停在函数调用的上一层。

### 5. 断点管理 (`breakpoint`)

你可以在 LLDB 中通过命令行来管理断点。

*   **`breakpoint set -f <文件名> -l <行号>`**: 在指定文件的指定行设置一个断点。
*   **`breakpoint set -n <函数名>`**: 在指定函数名上设置断点。
*   **`breakpoint list`**: 列出所有当前的断点。
*   **`breakpoint disable/enable <断点ID>`**: 禁用或启用一个断点。
*   **`breakpoint delete <断点ID>`**: 删除一个断点。

#### 条件断点

你可以为断点添加一个条件，只有当该条件满足时，断点才会被触发。

```lldb
(lldb) breakpoint set -f MyFile.swift -l 42 -c "i > 10"
```

### 6. 查看视图层级

在调试 UI 时，检查视图层级非常有用。

```lldb
# 打印当前视图控制器的视图层级 (Objective-C 风格)
(lldb) po [self.view recursiveDescription]

# 对于 SwiftUI，你可以使用更现代的方法
(lldb) po Mirror(reflecting: mySwiftUIView)
```

在 Xcode 12+ 中，你可以直接使用调试栏中的“Debug View Hierarchy”按钮，它提供了更直观的 3D 视图层级检查器。

### 7. 观察点 (`watchpoint`)

如果你想知道一个变量的**值在何时被改变**，你可以为其设置一个观察点。

```lldb
(lldb) watchpoint set variable self.myProperty
```

当 `self.myProperty` 的值发生任何改变时，程序都会暂停。

### 8. 读写内存与寄存器

在进行更底层的调试时，你可能需要直接检查内存地址和 CPU 寄存器的内容。

#### 读取内存 (`memory read` 或 `x`)

`memory read` 命令（别名 `x`）用于读取并格式化显示指定内存地址的内容。

```lldb
# 读取一个对象的内存地址
(lldb) p myObject
(MyObject) $R0 = 0x0000600001f3c000

# 以16进制格式，读取该地址开始的 64 个字节
(lldb) memory read 0x0000600001f3c000 -c 64

# 或者使用更简洁的 x 命令
# -f x: format hex (16进制)
# -s 8: size 8 bytes (64-bit)
# -c 8: count 8 (读取 8 * 8 = 64 字节)
(lldb) x -f x -s 8 -c 8 0x0000600001f3c000
```

#### 读取寄存器 (`register read`)

`register read` 命令用于查看当前 CPU 寄存器的值。这在调试汇编代码或追踪函数调用参数时非常有用。

```lldb
# 读取所有通用寄存器的值
(lldb) register read

# 读取特定的寄存器，例如 x0 (在 arm64 架构中通常是第一个参数)
(lldb) register read x0

# 读取栈指针 (sp) 和帧指针 (fp)
(lldb) register read sp fp
```

## `.lldbinit` 文件

为了提高效率，你可以创建一个名为 `~/.lldbinit` 的文件，并在其中定义你自己的命令别名或启动时自动执行的命令。

```
# ~/.lldbinit

# 为 po 创建一个更短的别名 ppo
command alias ppo expression -O --

# 每次启动 lldb 时，自动导入 UIKit
command script import UIKit
```

## 总结

LLDB 是一个极其强大的工具，它提供的能力远不止 `print` 和 `po`。

*   **基础**: 使用 `p` 和 `po` 来检查变量和对象。
*   **流程控制**: 使用 `c`, `n`, `s`, `finish` 来精确地控制程序的执行流程。
*   **动态修改**: 使用 `expression` 来在运行时改变变量的值或执行代码，这对于快速验证一个修复方案或测试不同状态非常有用。
*   **高级功能**: 学习使用**条件断点**和**观察点**，可以帮助你更高效地定位到问题的根源。
*   **底层调试**: 使用 `memory read` 和 `register read` 来深入探索程序的内存布局和执行状态。

花时间学习和实践 LLDB 的常用命令，是一项高回报的投资。它能让你在面对复杂的 bug 时，拥有“透视”程序内部状态的能力，从而更快、更准地找到并解决问题。
