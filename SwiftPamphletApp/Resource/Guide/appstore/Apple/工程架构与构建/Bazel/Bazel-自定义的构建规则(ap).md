# Bazel 自定义构建规则 (Custom Rules)

在 Bazel 中，虽然有 `rules_apple` 和 `rules_swift` 这样强大的官方规则库供你打包 iOS App 和编译 Swift 代码，但随着工程复杂度的提升，你不可避免地需要编写自己的**自定义规则 (Custom Rules)**。

## 1. 为什么需要自定义规则？

*   **代码生成 (Code Generation)**：你可能需要一个规则，能在编译前读取一段 JSON 或 GraphQL 结构，自动生成 Swift 的 Model 代码。
*   **资源处理**：自定义图片压缩流水线，在打包前对 xcassets 进行批量 WebP 转换。
*   **安全加固**：在二进制文件链接前，插入一个自动代码混淆（Obfuscation）的脚本节点。
*   **统一公司标准**：封装一个公司内部的 `my_company_ios_app` 规则，将所有的证书签名、预编译脚本隐藏起来，让业务开发线只需关心代码输入。

## 2. Starlark 语言基础

Bazel 的配置文件和规则都是使用 **Starlark** 语言编写的。这是一种类似于 Python 的方言，但为了保证构建的确定性（Hermeticity），它故意被设计成了**图灵不完备**的（不支持 `while` 循环、不支持无界递归、不支持读取系统时间）。

自定义规则通常写在后缀为 `.bzl` 的文件中。

## 3. 编写一个极简的自定义规则

自定义规则的核心是两个部分：**属性定义 (Attributes)** 和 **实现函数 (Implementation Function)**。

假设我们要写一个规则，读取一个 `.txt` 文件，将其内容转为大写，然后输出一个新的文件。

创建一个 `my_rules.bzl`：

```starlark
# 2. 实现函数：定义构建动作
def _uppercase_file_impl(ctx):
    # ctx (context) 包含了我们在 rule 中定义的所有属性
    input_file = ctx.file.src
    # 声明一个输出文件对象
    output_file = ctx.outputs.out

    # 定义具体的 Action (执行动作)
    ctx.actions.run_shell(
        inputs = [input_file],
        outputs = [output_file],
        # 这里的命令：使用 tr 把输入文件内容转大写，重定向到输出文件
        command = "tr '[:lower:]' '[:upper:]' < '%s' > '%s'" % (input_file.path, output_file.path)
    )
    
    # 告诉 Bazel，这个规则产出了哪些文件
    return [DefaultInfo(files = depset([output_file]))]

# 1. 规则定义
uppercase_file = rule(
    implementation = _uppercase_file_impl,
    # 定义输入和输出的属性
    attrs = {
        # src 是一个文件，且必须存在
        "src": attr.label(allow_single_file = True, mandatory = True),
        # out 定义了输出文件的名字
        "out": attr.output(mandatory = True),
    },
)
```

## 4. 在 BUILD 文件中使用规则

现在我们可以在项目的 `BUILD` 文件中加载并使用这个自定义规则了：

```starlark
# 从 .bzl 文件中导入我们刚才写的规则
load("//tools/rules:my_rules.bzl", "uppercase_file")

# 使用规则
uppercase_file(
    name = "make_it_upper",
    src = "hello.txt",
    out = "HELLO_UPPER.txt",
)
```

当你执行 `bazel build //:make_it_upper` 时，Bazel 会在沙盒中执行那个 shell 脚本，并缓存结果。

## 5. 宏 (Macros) 与 规则 (Rules) 的区别

除了 `rule`，你还经常会听到 `macro`。
*   **Rule (规则)**：向底层执行引擎注册了具体的 Action（比如运行个脚本，调个编译器编译器），并产生依赖图上的节点。
*   **Macro (宏)**：仅仅是 Starlark 的普通函数，它的作用是**组装现有的 Rules**。比如你写了一个函数，里面同时调用了 `swift_library` 和 `apple_bundle`，这就叫宏。宏在解析阶段（Loading Phase）就被展开了，Bazel 引擎底层只认展开后的 Rules。