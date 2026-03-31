# iOS/macOS 系统能力：密码自动填充 (Password Autofill)

密码自动填充（Password Autofill）是苹果在其生态系统中提供的一项核心功能，旨在提升用户在登录和注册流程中的安全性和便捷性。它允许用户安全地保存他们的网站和应用凭据（用户名和密码），并在需要时通过面容 ID（Face ID）、触控 ID（Touch ID）或设备密码来快速、安全地填充。

作为开发者，正确地集成密码自动填充功能，不仅能极大地改善用户体验，还能鼓励用户使用更强大、更独特的密码，从而提升应用的整体安全性。

## 核心理念：关联域 (Associated Domains)

密码自动填充的核心是**关联域（Associated Domains）**。你需要通过关联域，向系统证明你的应用和你的网站是属于同一个实体的。这样，保存在你的网站上的密码，就可以被你的应用所使用，反之亦然。

当用户在一个 `TextField` 中输入时，系统会检查这个应用的关联域。如果它在用户的“iCloud 钥匙串”中找到了匹配该域的已存凭据，就会在键盘的上方显示一个“密码”或“钥匙”按钮，提示用户可以进行自动填充。

## 实现步骤

### 1. 配置关联域

*   **网站端**: 你需要在你的网站服务器上，放置一个名为 `apple-app-site-association` 的 JSON 文件。这个文件没有扩展名，并且必须可以通过 `https://yourdomain.com/.well-known/apple-app-site-association` 的 URL 被 HTTPS 访问。

    ```json
    {
        "webcredentials": {
            "apps": [ "ABCDE12345.com.yourcompany.yourapp" ]
        }
    }
    ```
    *   `webcredentials`: 声明了与 Web 凭据相关的应用。
    *   `apps`: 一个数组，其中包含了你的应用的唯一标识符，格式为 `TeamID.BundleID`。

*   **Xcode 项目端**: 在 “Signing & Capabilities” 标签页中，添加 “Associated Domains” 能力，并添加一个格式为 `webcredentials:yourdomain.com` 的条目。

### 2. 正确设置 `TextField` 的 `textContentType`

这是在代码中实现自动填充的**最关键一步**。你需要为你的用户名和密码输入框，设置正确的 `textContentType`。这个修饰符向系统提供了关于该输入框期望输入内容类型的语义信息。

```swift
import SwiftUI

struct LoginForm: View {
    @State private var username = ""
    @State private var password = ""

    var body: some View {
        Form {
            TextField("用户名或邮箱", text: $username)
                // 1. 标记为用户名输入框
                .textContentType(.username)
                .keyboardType(.emailAddress)
            
            SecureField("密码", text: $password)
                // 2. 标记为密码输入框
                .textContentType(.password)
            
            Button("登录") { /* ... */ }
        }
    }
}

#Preview {
    LoginForm()
}
```

*   **`.textContentType(.username)`**: 告诉系统这个 `TextField` 是用于输入用户名的。
*   **`.textContentType(.password)`**: 告诉系统这个 `SecureField` 是用于输入密码的。

当系统看到这两个具有正确 `textContentType` 的输入框时，它就会在键盘上方自动显示密码填充的提示。

### 3. 处理新密码的保存

当用户在一个新的应用或网站上注册，或者修改密码时，系统会自动检测到这是一个新的凭据，并提示用户是否要将其保存到 iCloud 钥匙串中。这个行为是**完全自动**的，只要你的 `TextField` 和 `SecureField` 正确地设置了 `textContentType`。

## 一次性验证码 (One-Time Codes)

除了用户名和密码，自动填充也支持通过短信发送的一次性验证码（One-Time Codes）。

要启用这个功能，你只需要将 `TextField` 的 `textContentType` 设置为 `.oneTimeCode`。

```swift
TextField("验证码", text: $verificationCode)
    .textContentType(.oneTimeCode)
    .keyboardType(.numberPad)
```

当用户收到一条包含验证码的短信时，系统会自动从短信中解析出验证码，并将其显示在键盘上方的建议栏中，用户只需轻轻一点即可完成填充。

## 总结

在 SwiftUI 中集成密码自动填充功能非常简单，几乎所有的工作都由系统自动完成。作为开发者，你只需要做好两件事：

1.  **配置关联域**: 在你的网站和 Xcode 项目中正确地设置 `Associated Domains`，将你的应用和网站关联起来。这是实现密码在应用和网站之间共享的关键。

2.  **设置 `textContentType`**: 为你的输入框提供正确的语义类型。这是**最重要**的一步，它直接决定了系统是否会触发自动填充的 UI。
    *   用户名 -> `.username`
    *   密码 -> `.password`
    *   新密码 -> `.newPassword`
    *   短信验证码 -> `.oneTimeCode`

通过正确地实现密码自动填充，你不仅为用户提供了极大的便利，避免了他们记忆和输入复杂密码的麻烦，还通过鼓励使用强密码和 iCloud 钥匙串，显著地提升了你应用账户的安全性。
