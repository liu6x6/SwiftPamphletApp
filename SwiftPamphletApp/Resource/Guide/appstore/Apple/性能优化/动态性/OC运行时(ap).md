# Objective-C 运行时 (Runtime) 深度解析

Objective-C 是一门极其动态的语言。你在代码里写的绝大多数调用和声明，在编译成机器码时并没有被最终确定，而是被推迟到了**程序运行阶段 (Runtime)** 去决断。
支撑这套魔法的，就是位于系统底层的 C/汇编库：\`objc4\`（即大名鼎鼎的 Runtime 库）。

在性能优化、底层监控（APM）和逆向工程中，精通 OC Runtime 是资深 iOS 开发者的硬指标。

## 1. 核心基石：objc_msgSend (消息机制)

在 C 语言或 Swift (静态派发) 中，调用函数 \`[dog bark]\` 是直接跳到内存中 \`bark\` 对应的代码段执行。
而在 OC 中，\`[dog bark]\` 会被编译器残忍地翻译成一个底层的 C 函数调用：

```c
// 伪代码
objc_msgSend(dog, @selector(bark));
```
它的意思不是“执行 bark”，而是“向 dog 对象发送一个叫 bark 的消息”。如果 dog 对象在运行时没有这个方法，它不会立刻崩溃，而是进入一条极其复杂的**消息转发机制**。

**性能代价**：每次调用都要通过 \`isa\` 指针找到类对象，在方法缓存（cache_t）里查找。如果找不到，再顺着继承链去方法列表（method_list）里线性/二分查找。如果极高频调用（如列表滚动时的绘制计算），\`objc_msgSend\` 的开销会成为性能瓶颈。

## 2. 对象的本质：isa 指针

在 Runtime 眼里，一个对象 \`id\` 的本质就是一个包含了 \`isa\` 指针的 C 结构体 (\`objc_object\`)。

*   **对象 (Instance)** 的 \`isa\` 指向它的**类 (Class)**。当对象调用实例方法时，顺着 \`isa\` 去类里找。
*   **类 (Class)** 的本质也是个对象，它的 \`isa\` 指向它的**元类 (Meta-Class)**。当调用类方法（如 \`[NSString stringWithFormat:]\`）时，顺着 \`isa\` 去元类里找。
*   通过操控 \`isa\` 指针（isa-swizzling），可以在运行时让一个对象瞬间变成另一个类的实例。这是 Apple 底层实现 **KVO (键值观察)** 的核心原理（在运行时动态生成一个子类，并把对象的 isa 指向新子类）。

## 3. 终极魔法：Method Swizzling (方法交换)

这是 Runtime 被应用得最广泛（也是被滥用得最严重）的黑科技。
它允许你在 App 运行期间，强行将两个方法的底层实现（IMP，即代码的内存地址）进行对调。

**应用场景：无痕埋点 (AOP 面向切面编程)**
假设你想统计全 App 所有页面的进入次数。如果你去每个 Controller 里写 \`print\` 就太蠢了。
你可以在系统启动时，用 Method Swizzling 把 \`UIViewController\` 原生的 \`viewDidAppear:\` 和你自定义的 \`my_viewDidAppear:\` 交换。

```objc
// 典型的 Method Swizzling 核心代码
Method originalMethod = class_getInstanceMethod([UIViewController class], @selector(viewDidAppear:));
Method swizzledMethod = class_getInstanceMethod([UIViewController class], @selector(my_viewDidAppear:));

// 交换它们的底层实现指针 (IMP)
method_exchangeImplementations(originalMethod, swizzledMethod);

// 在你自定义的方法里：
- (void)my_viewDidAppear:(BOOL)animated {
    // 1. 插入你的埋点统计代码
    [Tracker logPageView:NSStringFromClass([self class])];
    
    // 2. 调回原来的原生逻辑。
    // 注意：因为名字已经被交换了，这里调用 my_viewDidAppear 其实执行的是原生底层的 viewDidAppear 汇编代码！绝不是死循环！
    [self my_viewDidAppear:animated]; 
}
```

## 4. 性能优化与 Runtime

过度滥用 Runtime 会给性能带来灾难：
1. **启动耗时（+load 的原罪）**：早期开发者喜欢在所有类的 \`+load\` 方法里写 Swizzling 代码。\`dyld\` 在启动 App 时，必须在进入 main 函数之前、以极高的优先级同步执行全工程所有的 \`+load\`。如果你有几百个类的 \`+load\`，App 启动时间会激增几百毫秒。（现代优化：推迟到 \`+initialize\` 或进入首页后再异步 Hook）。
2. **Category (分类) 的方法覆盖**：如果你在 Category 中写了一个和主类同名的方法，Runtime 会在加载方法列表时，把 Category 的方法排在前面，从而“覆盖”原方法。但这种覆盖是不确定的，排查起 Bug 来如同大海捞针。

## 5. 消息转发 (Message Forwarding)

当一个对象收到无法响应的消息时，它会经历三道防线：
1. **动态方法解析**：\`+resolveInstanceMethod:\`。你可以在这里临时用 \`class_addMethod\` 给它塞一个 C 语言函数进去救场。
2. **备用接收者**：\`-forwardingTargetForSelector:\`。你可以把消息甩锅给另一个对象：“我不会，但某某某会处理”。
3. **完整消息转发**：\`-forwardInvocation:\`。这是最后的机会，系统把方法名、参数全打包成一个 \`NSInvocation\` 给你，让你任意摆布。（许多底层解耦路由、JSPatch 等热修复框架基于此原理）。
