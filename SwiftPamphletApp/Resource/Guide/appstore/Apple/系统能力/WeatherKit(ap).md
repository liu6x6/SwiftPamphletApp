# iOS/macOS 系统能力：WeatherKit (iOS 16+)

WeatherKit 是苹果在 WWDC 2022 (iOS 16) 中推出的一个全新的、现代化的天气服务框架。它取代了之前陈旧的、数据源不稳定的天气 API，为开发者提供了直接访问苹果天气（Apple Weather）高质量、全球化天气数据的能力。

通过 WeatherKit，你可以轻松地在你的应用和网站中集成各种天气信息，包括当前天气、未来 10 天的逐日预报、未来一小时的分钟级降水预报、以及各种天气警报。

## 核心优势

*   **高质量数据**: 数据源与苹果自家的“天气”应用完全相同，由苹果提供和维护，具有全球覆盖和高准确性。
*   **隐私友好**: 所有的 API 请求都包含了隐私保护措施，苹果不会将你的用户位置信息与他们的个人身份关联起来。
*   **现代化的 Swift API**: 提供了基于 `async/await` 的现代化 Swift API，使用起来非常简单和直观。
*   **免费额度**: 每个苹果开发者账户每月提供 500,000 次的 API 调用免费额度，对于绝大多数中小型应用来说完全足够。

## 启用 WeatherKit

1.  **在开发者网站上启用**: 登录 Apple Developer 网站，在你的应用的 “Identifiers” 配置中，进入 “App Services” 标签页，并勾选 “WeatherKit”。
2.  **在 Xcode 中启用**: 在 Xcode 项目的 “Signing & Capabilities” 标签页中，添加 “WeatherKit” 能力。

## 核心用法：`WeatherService`

`WeatherService` 是你与 WeatherKit 交互的主要入口。它是一个单例对象，你可以通过 `WeatherService.shared` 来访问它。

所有的数据获取方法都是**异步**的，你需要在一个 `async` 上下文（如 `Task`）中调用它们。

### 获取当前天气

要获取某个地点的当前天气，你需要调用 `weather(for: CLLocation)` 方法。

```swift
import SwiftUI
import CoreLocation
import WeatherKit

struct CurrentWeatherView: View {
    @State private var currentWeather: CurrentWeather?
    let location = CLLocation(latitude: 39.9042, longitude: 116.4074) // 北京

    var body: some View {
        VStack {
            if let weather = currentWeather {
                Text("当前温度: \(weather.temperature.description)")
                Text("体感温度: \(weather.apparentTemperature.description)")
                Image(systemName: weather.symbolName)
                    .font(.largeTitle)
            } else {
                ProgressView()
            }
        }
        .task { // .task 会在视图出现时自动执行异步任务
            await fetchCurrentWeather()
        }
    }

    func fetchCurrentWeather() async {
        do {
            let weather = try await WeatherService.shared.weather(for: location)
            self.currentWeather = weather.currentWeather
        } catch {
            print("获取天气失败: \(error)")
        }
    }
}

#Preview {
    CurrentWeatherView()
}
```

在这个例子中：
1.  我们创建了一个 `CLLocation` 对象来表示我们想要查询的地点。
2.  在 `.task` 修饰符中，我们调用了 `fetchCurrentWeather` 异步函数。
3.  `WeatherService.shared.weather(for:)` 是核心 API。它会异步地返回一个包含多种天气数据的 `Weather` 对象。
4.  我们从返回的 `Weather` 对象中，取出 `currentWeather` 属性，并用它来更新视图的状态。
5.  `CurrentWeather` 对象中包含了如 `temperature` (温度), `apparentTemperature` (体感温度), `symbolName` (对应的 SF Symbol 名称) 等丰富的属性。

## 获取多种天气数据

`weather(for:including:)` 方法的 `including` 参数允许你一次性地请求多种类型的天气数据，以减少网络请求次数。

```swift
let allWeather = try await WeatherService.shared.weather(
    for: location,
    including: .current, .minute, .hourly, .daily, .alerts
)

let current = allWeather.currentWeather
let minuteForecast = allWeather.minuteForecast
let hourlyForecast = allWeather.hourlyForecast
let dailyForecast = allWeather.dailyForecast
let alerts = allWeather.weatherAlerts
```

*   **`.current`**: 当前天气。
*   **`.minute`**: 未来一小时的分钟级降水预报（仅在部分地区可用）。
*   **`.hourly`**: 未来几个小时的逐小时预报。
*   **`.daily`**: 未来 10 天的逐日预报。
*   **`.alerts`**: 该地区的恶劣天气警报。

每种预报都以一个 `Forecast` 对象的形式返回，它是一个包含了多个时间点天气快照的集合。

### 示例：显示逐日预报

```swift
struct DailyForecastView: View {
    @State private var dailyForecast: Forecast<DayWeather>?
    let location = CLLocation(latitude: 37.3347, longitude: -122.0090) // Cupertino

    var body: some View {
        List {
            if let forecast = dailyForecast {
                ForEach(forecast.forecast, id: \.date) { dayWeather in
                    HStack {
                        Text(dayWeather.date, format: .dateTime.weekday(.abbreviated))
                        Spacer()
                        Image(systemName: dayWeather.symbolName)
                        Text(dayWeather.highTemperature.formatted())
                        Text(dayWeather.lowTemperature.formatted()).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .task {
            do {
                self.dailyForecast = try await WeatherService.shared.weather(for: location, including: .daily)
            } catch { ... }
        }
    }
}
```

## 总结

WeatherKit 是一个设计精良、数据可靠、使用简单的天气服务框架。

*   **官方支持**: 由苹果提供和维护，数据质量有保证。
*   **现代 API**: 完全基于 `async/await`，与现代 Swift 并发模型无缝集成。
*   **丰富的数据**: 提供从当前天气到未来 10 天预报，再到分钟级降水和天气警报的全方位数据。
*   **易于集成**: 只需几个简单的步骤即可在你的应用中启用，并通过 `WeatherService.shared` 单例进行调用。

对于任何需要在应用中展示天气信息的需求——无论是作为核心功能（天气应用），还是作为辅助信息（旅行、户外活动应用）——WeatherKit 都是目前 iOS/macOS 平台上的最佳选择。
