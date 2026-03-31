# iOS 测试：代码覆盖率 (Code Coverage)

代码覆盖率（Code Coverage）是衡量测试套件（如单元测试、UI 测试）运行了多少应用源代码的一个核心指标。它可以帮助开发者找出那些未被测试用例覆盖到的代码路径，从而提高应用的稳定性和可靠性。

## 1. 开启代码覆盖率统计

在 Xcode 中，默认情况下代码覆盖率统计是关闭的，因为它会在编译和运行时引入一定的性能开销。

**如何开启：**
1. 点击 Xcode 顶部工具栏中的 Scheme 选择器，选择 `Edit Scheme...` (或按 `Cmd + Shift + <`)。
2. 在左侧面板中选择 `Test` 阶段。
3. 切换到 `Options` 标签页。
4. 勾选 `Code Coverage` 下的 `Gather coverage for`。
5. 建议选择 `some targets`（仅针对你想测试的特定 Target），而不是 `all targets`，以免收集无关的第三方库覆盖率，拖慢测试速度。

## 2. 查看代码覆盖率结果

运行测试 (`Cmd + U`) 后，你可以通过以下方式查看结果：

### 报告导航器 (Report Navigator)
1. 打开左侧导航栏的最后面的 `Report Navigator` (快捷键 `Cmd + 9`)。
2. 选中最新的一次 `Test` 运行记录。
3. 在上方切换到 `Coverage` 标签。
4. 在这里，你可以看到每个文件、每个类甚至每个函数的覆盖率百分比。

### 源码编辑器行内高亮
当你在查看某个具体的 `.swift` 源代码文件时：
1. 开启 Xcode 右侧的编辑区侧边栏 (Editor -> Show Code Coverage)。
2. 或者是直接观察代码编辑器的最右侧。
3. 未被测试覆盖到的代码行会显示为红色，并且如果鼠标悬停，可以清晰看到这行代码在测试运行期间执行了 `0` 次。执行过的行会显示执行的次数。

## 3. 覆盖率的目标与意义

*   **不要盲目追求 100%**：对于包含大量简单 Getter/Setter 或纯 UI 样式的代码，强行追求 100% 覆盖率往往收益极低且维护成本巨大。
*   **核心逻辑优先**：应该确保应用的核心业务逻辑、复杂的算法、网络解析层（ViewModel / Presenter 等）达到较高的覆盖率（例如 80% 以上）。
*   **防御性编程的陷阱**：有时候防御性代码（如 `guard let else { return }` 中的 `return` 分支）很难被常规流程触发。你可以专门编写异常测试用例来覆盖它们。

## 4. 命令行与 CI/CD 集成

在持续集成（CI）系统中，可以使用 `xcodebuild` 命令并结合 `xcresult` 文件来生成自动化的代码覆盖率报告：

```bash
xcodebuild test \
  -project MyApp.xcodeproj \
  -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES \
  -resultBundlePath ./TestResults.xcresult
```
配合使用像 `xcov`、`Slather` 或是 `SonarQube` 这样的第三方工具，可以将 `.xcresult` 转化为直观的 HTML 网页报告。