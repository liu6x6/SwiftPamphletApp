# fishhook：iOS 底层 C 语言 Hook 神器

在 iOS 性能优化和 APM（应用性能监控）系统开发中，我们经常需要**拦截（Hook）系统底层的 C 语言函数**。

比如：我想知道我的 App 里到底有哪些地方在调用 \`malloc\` 申请内存？我想在每次调用系统网络库 \`socket\` 或 \`connect\` 发请求前，偷偷塞一段我自己的耗时统计代码。

如果是 Objective-C 的方法，我们可以用 Method Swizzling (利用 Runtime 的 \`isa\` 和方法缓存交换)。
但是，对于纯 C 语言编写的底层系统函数（如 \`malloc\`, \`printf\`, \`open\`），它们的地址在编译时就近乎固定，OC Runtime 的那套魔法对它们**完全无效**。

这时候，就轮到 Meta (Facebook) 开源的神级极简库 **\`fishhook\`** 登场了。

## 1. 为什么叫 fish"hook"？(核心原理解析)

\`fishhook\` 只有仅仅两个文件 (\`fishhook.c\` 和 \`fishhook.h\`)，代码不到三百行，但它的原理极其精妙。

iOS/macOS 的可执行文件是 **Mach-O** 格式。为了安全和共享内存，系统广泛使用了 **PIC (Position Independent Code，位置无关代码)** 和动态链接技术。
当你的 App 代码里调用了一个系统的 C 函数，比如 \`printf("Hello")\`，编译器并不知道 iOS 系统库里的 \`printf\` 到底在内存的哪个物理地址。

于是，Mach-O 文件里会留一个**“空位” (表)**，这个表叫作 **\`__la_symbol_ptr\` (Lazy Symbol Pointers 懒加载符号指针表)** 或 \`__nl_symbol_ptr\`。
当你的 App 第一次运行到 \`printf\` 时，系统的动态链接器 (\`dyld\`) 才会去系统底层的 \`libSystem.B.dylib\` 库里找到真正的 \`printf\` 函数的物理内存地址，并把这个地址“填”到你的 Mach-O 文件的那个表（空位）里。
以后再调用，就直接顺着表里的地址跳过去了。

**fishhook 的原理就是“偷天换日”：**
既然你的 App 是去查那个**表**来找地址的，fishhook 就利用 C 语言指针，极其暴力地直接修改了 Mach-O 文件在内存中那张**表里的物理指针记录**。它把原本指向系统 \`printf\` 的指针，抹掉，改成了指向你自定义的一个 C 函数的指针！

## 2. 基础使用演示

它的 API 简单到令人发指。

```c
#import "fishhook.h"
#import <dlfcn.h>

// 1. 定义一个函数指针，用来保存原来那个真实的系统函数的地址
static int (*original_open)(const char *, int, ...);

// 2. 写一个你自己的假冒函数 (参数和返回值必须和原系统函数一模一样！)
int my_fake_open(const char *path, int oflag, ...) {
    // 你可以在这里做任何事！比如统计全 App 到底打开了多少个文件，打开的是什么文件。
    printf("【拦截警告】App 正在试图打开底层文件: %s\n", path);
    
    // 3. 统计完了，别忘了调回原来真正的系统函数，否则 App 就崩了
    // 如果有变长参数，处理起来需要用 va_list，这里为了演示简化
    return original_open(path, oflag); 
}

// 4. 在 App 启动的最早期 (如 main 函数或 +load 中) 执行 Hook
void performHook() {
    // 构造结构体告诉 fishhook 你的意图
    struct rebinding open_rebinding = {
        "open",                // 要 Hook 的目标 C 函数的字符串名字
        (void *)my_fake_open,  // 你写的假冒函数的地址
        (void **)&original_open // 让 fishhook 把真实的地址存到你这个指针变量里
    };
    
    // 执行 Hook！(传入一个数组，可以同时 Hook 几百个函数)
    rebind_symbols((struct rebinding[1]){open_rebinding}, 1);
}
```

## 3. fishhook 的绝对限制

这是面试中最常被问到的一个知识点：**fishhook 到底不能 Hook 什么？**

**答案：fishhook 绝对无法 Hook 你自己 App 内部（也就是同一个 Mach-O 镜像内）定义的 C 语言函数。**

**为什么？**
回到原理解析：fishhook 修改的是用于链接**外部共享动态库**的懒加载符号表 (\`__la_symbol_ptr\`)。
如果你在自己的代码里写了一个 \`void my_math_func()\`，并且自己在别的地方调用了它。编译器在编译期就已经算出了它们在同一个文件内的相对偏移量，直接通过汇编的相对跳转指令 (\`bl 或 b\`) 跳过去了。**这中间根本不经过那张外部符号表！** fishhook 连修改的地方都找不到。

## 4. 工业级 APM 的应用

在微信、抖音等超级 App 的自研 APM 性能监控系统中，fishhook 被疯狂使用：
*   **内存泄漏监控**：Hook 系统的 \`malloc\`, \`calloc\`, \`free\`。记录每一块被分配的内存地址和大小。
*   **极端的耗时统计**：Hook 系统的底层线程创建函数 \`pthread_create\` 或是极底层的消息派发函数 \`objc_msgSend\` 的底层依赖。
