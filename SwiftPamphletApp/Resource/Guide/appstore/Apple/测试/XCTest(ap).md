# XCTest 基础使用指南

`XCTest` 是 Apple 官方提供的，深度集成在 Xcode 中的自动化测试框架。它支持单元测试、性能测试和 UI 测试。

## 1. 创建测试 Target

在 Xcode 中，测试代码是与主应用代码分离的。如果你在创建工程时没有勾选 `Include Tests`，可以通过菜单栏手动添加：
**File -> New -> Target...** -> 选择 `Unit Testing Bundle` 或 `UI Testing Bundle`。

## 2. 编写单元测试基础结构

一个标准的单元测试文件通常长这样：

```swift
import XCTest
// 使用 @testable 引入你的主 App 模块，这样才能访问内部标记为 internal 的类和方法
@testable import MyApp 

final class MathUtilsTests: XCTestCase {

    // 1. Setup: 在每个测试用例执行【前】调用。用于初始化环境、重置状态。
    override func setUpWithError() throws {
        // ...
    }

    // 2. Teardown: 在每个测试用例执行【后】调用。用于清理内存、关闭连接等。
    override func tearDownWithError() throws {
        // ...
    }

    // 3. 测试用例: 方法名必须以 "test" 开头，不带参数，没有返回值。
    func testAddition() throws {
        // Arrange (准备)
        let a = 5
        let b = 3
        
        // Act (执行)
        let result = MathUtils.add(a, b)
        
        // Assert (断言验证)
        XCTAssertEqual(result, 8, "5 加上 3 应该等于 8")
    }
}
```

## 3. 常用断言 (Assertions)

断言是测试的核心，如果断言失败，该测试用例就会被标记为失败（红叉）。

*   **布尔测试**:
    *   `XCTAssertTrue(expression)`：验证表达式为真。
    *   `XCTAssertFalse(expression)`：验证表达式为假。
*   **相等性测试**:
    *   `XCTAssertEqual(expr1, expr2)`：验证两个值相等。
    *   `XCTAssertNotEqual(expr1, expr2)`
*   **Nil 测试**:
    *   `XCTAssertNil(expression)`：验证对象为 nil。
    *   `XCTAssertNotNil(expression)`：验证对象不为 nil。
*   **异常/错误测试**:
    *   `XCTAssertThrowsError(expression)`：验证某段代码抛出了 Error。
    *   `XCTAssertNoThrow(expression)`：验证代码执行没有抛出 Error。
*   **无条件失败** (常用于强制失败或写在不该进入的 `switch` / `guard` 分支中):
    *   `XCTFail("代码不应该执行到这里")`

## 4. 异步代码测试 (Expectations)

测试网络请求或定时器等异步代码时，不能直接断言，因为测试用例函数会立刻返回。必须使用 `XCTestExpectation`。

```swift
func testNetworkFetch() throws {
    // 1. 创建预期
    let expectation = XCTestExpectation(description: "Fetch data from server")
    
    // 2. 执行异步操作
    NetworkManager.fetchUser { user in
        XCTAssertNotNil(user)
        // 3. 标记预期已达成
        expectation.fulfill() 
    }
    
    // 4. 等待预期，设置超时时间。如果时间到了还没调用 fulfill，测试就会失败。
    wait(for: [expectation], timeout: 5.0)
}
```

## 5. 性能测试 (Performance Testing)

你可以使用 `measure` 闭包来测试某段特定代码的执行耗时。Xcode 会自动运行 10 次并计算平均值，如果你的后续代码修改导致耗时大幅增加（超过设定的 Baseline），测试就会报错。

```swift
func testSortingPerformance() throws {
    let largeArray = (0...10000).map { _ in Int.random(in: 1...1000) }
    
    // 测试这块代码的性能
    self.measure {
        let _ = largeArray.sorted()
    }
}
```

## 运行测试
*   使用快捷键 `Cmd + U` 运行全套测试。
*   点击编辑器行号旁边的小菱形图标，可以单独运行某个特定的测试类或测试方法。