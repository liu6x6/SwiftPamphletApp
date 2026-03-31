# 农历与公历的转换处理

在中国区应用（如日历、天气、黄历、节假日提醒等）开发中，将标准的公历（Gregorian Calendar）日期转换为农历（Chinese Calendar），甚至是互转，是一个绝对的刚需。

好消息是：**Apple 原生的 Foundation 框架自带了极其强大、准确的农历计算引擎！你完全不需要引入庞大且容易算错闰月的第三方农历库！**

## 1. 核心原理：切换 Calendar.Identifier

时间（\`Date\`）是绝对的，而日历（\`Calendar\`）是解释时间的规则。
公历的规则是 \`.gregorian\`，而农历的规则是 **\`.chinese\`**。我们只需要把同一个 \`Date\` 喂给使用 \`.chinese\` 规则的日历引擎，它就会吐出农历的日期组件（\`DateComponents\`）。

## 2. 实战：公历转农历字符串

假设今天是公历 2024年2月10日（大年初一）。

```swift
import Foundation

func getChineseLunarDate(from date: Date) -> String {
    // 1. 创建一个声明为“中国农历”的日历实例
    let chineseCalendar = Calendar(identifier: .chinese)
    
    // 2. 为了保证输出结果是中文（"正月", "初一"），必须指定地区和语言
    // "zh_CN" 极其重要，如果用默认的英文环境，它可能输出 "Month 1, Day 1"
    let formatter = DateFormatter()
    formatter.calendar = chineseCalendar
    formatter.locale = Locale(identifier: "zh_CN")
    
    // 3. 设置你想要的输出格式
    // U: 农历年份（如甲辰年）
    // MMMM: 农历月份（如正月、闰二月）
    // d: 农历日（如初一、廿五）
    formatter.dateFormat = "U MMMM d"
    
    // 4. 将绝对的 Date 转换为农历字符串
    return formatter.string(from: date)
}

let today = Date()
print("今天是农历: \(getChineseLunarDate(from: today))")
// 输出示例: "甲辰年 正月 初一"
```

## 3. 实战：精确提取农历数字与处理闰月

有时我们不想直接输出字符串，我们需要具体的数字来做逻辑判断（比如：今天是不是除夕？这个月是不是闰月？）

```swift
func checkLunarInfo(for date: Date) {
    let chineseCalendar = Calendar(identifier: .chinese)
    
    // 提取农历的 月、日，以及最重要的 isLeapMonth (是否闰月)
    let components = chineseCalendar.dateComponents([.month, .day, .isLeapMonth], from: date)
    
    guard let lunarMonth = components.month,
          let lunarDay = components.day,
          let isLeap = components.isLeapMonth else { return }
    
    print("农历第 \(lunarMonth) 个月，第 \(lunarDay) 天")
    
    if isLeap {
        print("注意：这是一个闰月！(比如闰二月)")
    }
    
    if lunarMonth == 8 && lunarDay == 15 {
        print("今天是中秋节！")
    }
}
```

## 4. 逆向操作：农历数字转回公历 Date

如果用户在 UI 上选择了他出生在“农历 1990 年 闰四月 十五”，你需要把它转成一个标准的 \`Date\` 以存入数据库。

```swift
func getGregorianDateFromLunar(year: Int, month: Int, day: Int, isLeapMonth: Bool) -> Date? {
    var chineseCalendar = Calendar(identifier: .chinese)
    // 确保时区是中国时区，避免几个小时的误差导致跳天
    chineseCalendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    
    // 构造农历的 DateComponents
    var lunarComponents = DateComponents()
    // 注意：农历的 year 在系统内部的计算方式非常复杂（通常以 60 年为一个甲子循环计算）
    // 所以在 Swift 中指定农历年份，我们不能给 year，而应该给 yearForWeekOfYear (实际业务中尽量用公历存，只在展示时转农历，双向互转容易因为系统内部年份映射出现极其诡异的 Bug)
    
    // 更安全的做法是，遍历公历寻找匹配的日子（略为复杂，不在此展开）。
    // 在真实开发中，如果是存储生日，建议让用户选公历，只用农历做辅助展示。
    
    return nil
}
```

**终极建议**：农历的历法极其复杂（涉及天文学计算），Apple 的 \`Calendar(identifier: .chinese)\` 在展示（提取年月、格式化输出）上是绝对可靠的。但涉及到把用户输入的农历逆向转回 \`Date\` 时，要非常小心跨越周期的计算陷阱。
