# iOS 安全：Keychain 基础与使用

在 iOS 和 macOS 开发中，如果你需要存储敏感的简短数据（如用户密码、API Token、加密密钥等），**绝对不能**使用 `UserDefaults` 或普通的 `Plist`、`SQLite` 文件，因为这些数据是以明文存储在文件系统中的，设备一旦被破解（越狱）极易泄漏。

Apple 提供了一个系统级的安全存储服务：**Keychain（钥匙串）**。

## 1. 什么是 Keychain？

Keychain 是 Apple 操作系统中提供的一种安全存储机制，由系统层级的独立加密守护进程管理。
*   **安全性高**：存储在 Keychain 中的数据使用设备级别的加密手段（基于硬件的加密引擎）保护。
*   **跨应用共享**：通过配置 App Groups（Keychain Sharing），同一个开发者账号下的多个应用可以共享读取某些 Keychain 密码。
*   **持久性强**：即使用户卸载了你的应用，存储在 Keychain 中的数据依然可以保留（除非你显式删除）。当用户重新安装应用时，可以自动恢复登录状态（这在某些场景下需要注意用户隐私清理）。
*   **iCloud 同步**：用户可以选择将 Keychain 项同步到 iCloud，从而在他们的所有苹果设备上自动填充密码。

## 2. Keychain 的核心结构

与 Keychain 交互通常涉及以下三个核心参数：
1.  **Item Class (项类别)**：这决定了你存储的数据的类型。最常用的是 `kSecClassGenericPassword`（普通密码/Token），此外还有 `kSecClassInternetPassword`（带有 URL 信息的密码）、`kSecClassKey`、`kSecClassCertificate` 等。
2.  **Attributes (属性/标识符)**：用于查询或区分不同密码。对于普通密码，通常使用：
    *   `kSecAttrService`：服务名称（例如你的 App 的 Bundle ID）。
    *   `kSecAttrAccount`：账号名称（例如用户的用户名、邮箱，或 `auth_token` 这样的标签）。
3.  **Data (数据本身)**：实际加密保存的秘密数据（类型为 `Data`），使用 `kSecValueData` 键表示。

## 3. Keychain 的底层 API (Security 框架)

苹果原生的 C 语言风格 API (`SecItemAdd`, `SecItemCopyMatching`, `SecItemUpdate`, `SecItemDelete`) 非常底层且难用，充满了繁琐的指针转换和配置字典。

**一个极其基础的保存数据示例：**
```swift
import Security
import Foundation

func saveToKeychain(account: String, data: Data) -> Bool {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword, // 类型：普通密码
        kSecAttrAccount as String: account,            // 账号标识
        kSecValueData as String: data,                 // 要保存的秘密数据
        // 访问控制：设备解锁后才允许访问
        kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
    ]
    
    // 先尝试删除可能已存在的旧数据
    SecItemDelete(query as CFDictionary)
    
    // 添加新项
    let status = SecItemAdd(query as CFDictionary, nil)
    return status == errSecSuccess
}
```

## 4. 推荐做法：使用第三方库

由于原生 API 过于晦涩，iOS 开发社区强烈推荐使用第三方封装库来操作 Keychain。它们将复杂的字典配置封装成了 Swift 风格的简洁 API。

**主流的第三方 Keychain 库：**
1. **KeychainAccess** (最著名，极简 API)
2. **Valet**
3. **SwiftKeychainWrapper** (由 Square 开源)

**使用 `KeychainAccess` 示例：**
```swift
import KeychainAccess

// 实例化一个与你的 App 相关联的 Keychain 实例
let keychain = Keychain(service: "com.example.MyApp")

// 存储 Token
do {
    try keychain.set("secret_api_token_12345", key: "UserAuthToken")
} catch let error {
    print("保存失败: \(error)")
}

// 读取 Token
do {
    let token = try keychain.get("UserAuthToken")
    print("获取到 token: \(token ?? "nil")")
} catch {
    print("读取失败")
}
```

## 5. 生物识别与高级访问控制

Keychain 不仅仅是一个安全的加密字典，它还能与 **Face ID / Touch ID** 深度结合。
通过设置 `SecAccessControl`，你可以强制要求：只有当用户成功通过生物识别验证后，系统才允许提取并解密这个密码。这是现代金融类 App 安全存储指纹支付私钥的核心技术。