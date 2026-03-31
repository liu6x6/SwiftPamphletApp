# 小组件中的网络请求处理

在 Widget 中发起网络请求是一个非常常见的需求（比如天气、股票、新闻看板），但这与在主 App 中发起请求有着本质的不同。小组件的生命周期极短，且受到严格的系统资源约束。

## 1. 核心规则与限制

*   **绝对的时效性**：系统调用你的 \`timeline()\` 方法后，你必须尽快返回 \`Timeline\` 对象。如果你的网络请求耗时过长（超过几十秒），系统会强行终止进程，小组件将无法更新，甚至变成纯黑白屏幕。
*   **没有长连接**：你不能在小组件里使用 WebSocket、Socket.IO 或长轮询（Long-polling）。必须是短平快的 HTTP 请求。
*   **内存极度受限**：小组件被分配的内存配额极小（旧设备可能只有 30MB 左右）。下载巨大的 JSON 或高清图片极易导致 Crash (OOM)。

## 2. 现代写法：Async/Await 与 URLSession

在 iOS 17 (搭配 \`AppIntentTimelineProvider\`) 中，网络请求的代码非常简洁：

```swift
func timeline(for configuration: ConfigurationIntent, in context: Context) async -> Timeline<NewsEntry> {
    do {
        // 1. 构造请求
        let url = URL(string: "https://api.example.com/news")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // 2. 检查响应
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // 如果网络失败，不要崩溃，返回一个带有错误提示的 Entry，并要求系统稍后（比如5分钟后）重试
            let errorEntry = NewsEntry(date: Date(), title: "加载失败", content: "网络错误")
            let retryDate = Date().addingTimeInterval(5 * 60)
            return Timeline(entries: [errorEntry], policy: .after(retryDate))
        }
        
        // 3. 解析数据
        let newsData = try JSONDecoder().decode(NewsResponse.self, from: data)
        let entry = NewsEntry(date: Date(), title: newsData.title, content: newsData.content)
        
        // 4. 成功后，按正常策略刷新（比如1小时后）
        let nextUpdate = Date().addingTimeInterval(60 * 60)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
        
    } catch {
        // 异常处理逻辑同上
        let errorEntry = NewsEntry(date: Date(), title: "请求出错", content: error.localizedDescription)
        return Timeline(entries: [errorEntry], policy: .after(Date().addingTimeInterval(300)))
    }
}
```

## 3. 图片下载的特殊处理

如果你需要在小组件里显示网络图片，**千万不要使用 \`AsyncImage\`**！
因为 \`AsyncImage\` 是在视图渲染时才发起网络请求的，而小组件的渲染环境不允许即时的网络 IO。

**正确的做法**：必须在 \`Provider\` 的 \`timeline()\` 方法中将图片下载为 \`Data\` 或者是保存为本地磁盘 \`URL\`，然后将这个数据传递给 \`TimelineEntry\`，最后在 View 中通过 \`Image(uiImage: UIImage(data: data)!)\` 同步渲染出来。

```swift
// 在 timeline 方法中
let imageData = try await URLSession.shared.data(from: imageURL).0
let entry = MyEntry(date: Date(), imageData: imageData)

// 在 View 中
if let uiImage = UIImage(data: entry.imageData) {
    Image(uiImage: uiImage).resizable()
}
```

## 4. 共享网络层代码

为了避免主 App 和 Widget Extension 中写两遍一样的网络代码，应该：
1. 创建一个独立的 Swift 文件封装网络逻辑。
2. 在该文件的右侧边栏（Target Membership）中，同时勾选 **主 App Target** 和 **Widget Extension Target**。
3. 或者更高级地，将网络层打包成一个本地的 Swift Package，然后主 App 和 Widget 共同依赖它。
