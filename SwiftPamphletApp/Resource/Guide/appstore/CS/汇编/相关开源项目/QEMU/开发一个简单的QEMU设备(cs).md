# QEMU 实践：开发一个简单的设备模型

为 QEMU 添加一个新的虚拟设备，是深入理解其 I/O 子系统、QOM 对象模型和设备-驱动交互的最佳实践。我们将以创建一个最简单的、只有一个“只读状态寄存器”的虚拟设备为例，来走过整个开发流程。

**目标**: 创建一个名为 `my-device` 的新设备。这个设备，有一个 32 位的只读寄存器，其地址为 `0x0`。当 CPU 读取这个寄存器时，它将返回一个魔数 `0x12345678`。

## 1. 创建设备源码文件

在 `hw/misc/` 目录下，创建一个新的 C 文件 `my_device.c`。`hw/misc/` 目录，通常用于存放一些不属于任何特定类别（如存储、网络）的简单设备。

## 2. 定义设备状态结构体

在 `my_device.c` 中，首先定义一个结构体，来表示我们设备的状态。

```c
#include "hw/sysbus.h"
#include "hw/qdev-core.h"
#include "migration/vmstate.h"

// 定义设备类型名称
#define TYPE_MY_DEVICE "my-device"
// 一个宏，用于将 Object* 安全地转换为 MyDeviceState*
#define MY_DEVICE(obj) OBJECT_CHECK(MyDeviceState, (obj), TYPE_MY_DEVICE)

typedef struct MyDeviceState {
    // 继承自 SysBusDevice，这是最简单的总线设备父类型
    SysBusDevice parent_obj;

    // 设备的 MMIO 内存区域
    MemoryRegion iomem;

    // 我们设备的内部状态（虽然在这个例子中，我们返回的是一个常量）
    uint32_t status_register;

} MyDeviceState;
```

## 3. 实现 MMIO 读写回调

接下来，实现当 CPU 访问我们设备的 MMIO 区域时，应该被调用的函数。

```c
// 读回调函数
static uint64_t my_device_read(void *opaque, hwaddr addr, unsigned size) {
    // opaque 指针，实际上就是 MyDeviceState 的实例指针
    MyDeviceState *s = opaque;

    // 检查访问的偏移地址
    if (addr == 0x0) {
        printf("CPU is reading from my-device status register!\n");
        // 返回我们的魔数
        return 0x12345678;
    }

    // 对于其他地址，返回 0
    return 0;
}

// 写回调函数 (由于我们的寄存器是只读的，所以这个函数什么也不做)
static void my_device_write(void *opaque, hwaddr addr, uint64_t value, unsigned size) {
    MyDeviceState *s = opaque;
    printf("CPU is trying to write to my-device (read-only)!\n");
}

// 将读写函数，绑定到一个 MemoryRegionOps 结构体中
static const MemoryRegionOps my_device_ops = {
    .read = my_device_read,
    .write = my_device_write,
    .endianness = DEVICE_NATIVE_ENDIAN,
};
```

## 4. 实现设备初始化函数

这个函数，会在 QEMU 创建我们的设备实例时被调用。

```c
static void my_device_init(Object *obj) {
    MyDeviceState *s = MY_DEVICE(obj);

    // 初始化我们的 MMIO 内存区域
    // - opaque: 传递给回调函数的指针 (即设备状态本身)
    // - ops: 关联上我们的读写回调函数
    // - size: 定义我们的 MMIO 区域大小 (例如 4KB)
    memory_region_init_io(&s->iomem, obj, &my_device_ops, s, "my-device-io", 0x1000);

    // 将这个 MMIO 区域，注册到系统总线上
    sysbus_init_mmio(SYS_BUS_DEVICE(s), &s->iomem);
}
```

## 5. 注册设备类型

最后，使用 QOM 的 API，来将我们的设备，“介绍”给 QEMU 的类型系统。

```c
static const TypeInfo my_device_info = {
    .name          = TYPE_MY_DEVICE,       // 类型名称
    .parent        = TYPE_SYS_BUS_DEVICE,  // 父类型
    .instance_size = sizeof(MyDeviceState),// 实例大小
    .instance_init = my_device_init,       // 初始化函数
};

// 这个函数，会在 QEMU 启动时，被自动调用
static void my_device_register_types(void) {
    type_register_static(&my_device_info);
}

// 将我们的注册函数，添加到 QEMU 的初始化调用列表中
type_init(my_device_register_types)
```

## 6. 修改构建系统

为了让我们的新文件 `my_device.c` 被编译，我们需要修改其所在目录的 `meson.build` 文件。

打开 `hw/misc/meson.build`，并在 `softmmu_ss.add(` 的列表中，添加我们的文件名：

```meson
softmmu_ss.add(files(
    'unimp.c',
    'vmcoreinfo.c',
    'my_device.c',  // <-- 添加这一行
))
```

## 7. 在机器模型中使用我们的设备

现在，我们的设备，已经成为了 QEMU 的一个“已知零件”。我们可以在任何一个机器模型中，来“组装”它。让我们以 `virt` 这个通用的 ARM 平台为例。

修改 `hw/arm/virt.c` 中的 `virt_init` 函数：

```c
// 在 hw/arm/virt.c 的 virt_init 函数中
static void virt_init(MachineState *machine) {
    // ... 原有的 CPU, RAM 等初始化代码 ...

    // 创建我们的设备实例
    DeviceState *mydev = qdev_new("my-device");
    // 将其连接到系统总线
    sysbus_realize_and_unref(SYS_BUS_DEVICE(mydev), &error_fatal);
    // 将其 MMIO，映射到物理地址 0x0a000000
    sysbus_mmio_map(SYS_BUS_DEVICE(mydev), 0, 0x0a000000);

    // ... 原有的其他设备初始化代码 ...
}
```

## 8. 编译、运行与测试

1.  **重新编译 QEMU**: `make`
2.  **创建一个简单的裸机测试程序 (`test.c`)**: 
    ```c
    #define MY_DEVICE_ADDR 0x0a000000
    #define SERIAL_ADDR    0x09000000

    void print_char(char c) {
        *(volatile char *)SERIAL_ADDR = c;
    }

    void print_hex(unsigned int val) {
        char *hex = "0123456789abcdef";
        for (int i = 28; i >= 0; i -= 4) {
            print_char(hex[(val >> i) & 0xF]);
        }
    }

    void _start() {
        volatile unsigned int *my_dev_reg = (unsigned int *)MY_DEVICE_ADDR;
        unsigned int magic = *my_dev_reg; // 从我们的设备读取魔数

        print_hex(magic); // 通过串口，打印出这个魔数

        while(1);
    }
    ```
3.  **编译裸机程序**: `aarch64-none-elf-gcc -g -c test.c -o test.o && aarch64-none-elf-ld -Ttext=0x40000000 test.o -o test.elf`
4.  **运行 QEMU**: 
    ```bash
    ./qemu-system-aarch64 -M virt -cpu cortex-a72 -kernel test.elf -nographic
    ```

**预期结果**: 
你应该能在 QEMU 的控制台上，看到以下输出：

`CPU is reading from my-device status register!`
`12345678`

这证明了，我们的客户机程序，成功地通过 MMIO，访问到了我们的虚拟设备，并读取到了我们预设的魔数，然后通过另一个虚拟设备（串口），将其打印了出来。

## 总结

这个简单的例子，完整地展示了在 QEMU 中，创建一个新设备的核心流程。它虽然简单，但却包含了设备模拟的所有关键要素：**QOM 类型定义**、**MMIO 回调实现**、**设备初始化**，以及最终在**机器模型中的实例化**。以此为起点，你就可以通过阅读更复杂的设备源码，来逐步地学习如何实现中断、DMA 等更高级的设备交互功能。
