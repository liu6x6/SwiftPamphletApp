# SwiftUI 中的 TextField 视图

`TextField` 是 SwiftUI 中用于捕获用户单行文本输入的核心组件。它是构建登录表单、搜索框、设置页面等几乎所有需要用户输入文本信息的界面的基础。

## 核心用法：绑定状态

`TextField` 的工作方式是通过**双向绑定**到一个字符串类型的 `@State` 变量。这意味着 `TextField` 的内容与该状态变量始终保持同步。

```swift
import SwiftUI

struct BasicTextFieldExample: View {
    @State private var username: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text("当前输入: \(username)")
            
            // 创建一个 TextField
            // 第一个参数是占位符（placeholder）
            // text 参数绑定到 @State 变量
            TextField("请输入用户名", text: $username)
                .textFieldStyle(.roundedBorder) // 应用圆角边框样式
        }
        .padding()
    }
}

#Preview {
    BasicTextFieldExample()
}
```

在这个例子中：
1.  `username` 状态变量存储着 `TextField` 的当前值。
2.  `TextField` 的第一个参数 `"请输入用户名"` 是在输入框为空时显示的占位符文本。
3.  `text: $username` 使用 `$` 符号创建了一个到 `username` 的双向绑定。当用户在输入框中键入时，`username` 会被实时更新；反之，如果代码修改了 `username` 的值，输入框中的文本也会随之改变。

## 自定义 `TextField` 的样式

SwiftUI 提供了一系列修饰符来定制 `TextField` 的外观和行为。

### `.textFieldStyle()`

这个修饰符用于应用预设的样式。

*   `.plain`: 默认样式，无任何背景或边框。
*   `.roundedBorder`: 带有圆角和灰色边框的常见样式。
*   `.automatic`: 根据上下文自动选择合适的样式。

```swift
struct TextFieldStyleExample: View {
    @State private var text = ""
    var body: some View {
        Form {
            TextField("Plain Style", text: $text)
                .textFieldStyle(.plain)
            
            TextField("Rounded Border Style", text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
```

### 安全输入：`SecureField`

对于密码等敏感信息的输入，应该使用 `SecureField`。它的用法与 `TextField` 完全相同，但它会自动将用户输入的内容显示为圆点。

```swift
@State private var password = ""
SecureField("请输入密码", text: $password)
    .textFieldStyle(.roundedBorder)
```

### 键盘类型：`.keyboardType()`

你可以指定当用户点击 `TextField` 时弹出的键盘类型，以优化特定数据的输入体验。

```swift
TextField("邮箱地址", text: $email)
    .keyboardType(.emailAddress) // 弹出带有 '@' 和 '.' 符号的键盘

TextField("手机号码", text: $phoneNumber)
    .keyboardType(.phonePad) // 弹出数字电话键盘
```

### 提交行为：`onSubmit`

当用户点击键盘上的“完成”、“搜索”或“前往”按钮时，你可以通过 `onSubmit` 修饰符来触发一个操作。

```swift
@State private var searchText = ""

TextField("搜索...", text: $searchText)
    .onSubmit {
        // 当用户点击键盘上的“搜索”按钮时执行
        print("开始搜索: \(searchText)")
    }
    .submitLabel(.search) // 将键盘返回键的标签改为“搜索”
```

`.submitLabel()` 修饰符可以改变键盘返回键的标签，以更好地匹配上下文。

### 焦点管理 (iOS 15+)：`@FocusState`

在 iOS 15 及更高版本中，你可以使用 `@FocusState` 属性包装器来以编程方式控制哪个输入框应该获得焦点（即，激活键盘）。

```swift
enum LoginFormFocus {
    case username, password
}

struct FocusStateExample: View {
    @State private var username = ""
    @State private var password = ""
    @FocusState private var focusedField: LoginFormFocus?

    var body: some View {
        Form {
            TextField("用户名", text: $username)
                .focused($focusedField, equals: .username) // 绑定焦点状态
                .submitLabel(.next)

            SecureField("密码", text: $password)
                .focused($focusedField, equals: .password)
                .submitLabel(.done)
        }
        .onSubmit {
            // 当在一个输入框中提交时，自动切换到下一个
            switch focusedField {
            case .username:
                focusedField = .password
            default:
                print("登录中...")
                focusedField = nil // 关闭键盘
            }
        }
        .onAppear {
            // 视图出现时，自动聚焦到用户名输入框
            focusedField = .username
        }
    }
}
```

这个例子展示了一个完整的登录表单焦点管理流程：
1.  定义一个 `LoginFormFocus` 枚举来表示不同的输入框。
2.  使用 `@FocusState` 声明一个 `focusedField` 变量。
3.  使用 `.focused()` 修饰符将每个输入框与一个枚举值关联起来。
4.  在 `onSubmit` 中，根据当前焦点的位置，决定是将焦点切换到下一个输入框，还是执行最终的登录操作。
5.  在 `onAppear` 中，设置初始焦点。

## 总结

`TextField` 是 SwiftUI 中一个基础但功能强大的组件。掌握它的核心用法——状态绑定、样式设置、键盘类型和提交行为——是构建任何交互式应用的必备技能。对于更高级的用例，尤其是需要精确控制用户输入流程的表单，学习并使用 `@FocusState` 将极大地提升应用的用户体验。
