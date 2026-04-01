# QEMU 源码解析：设备模拟

设备模拟，是 QEMU 能够运行一个完整操作系统的核心能力之一。QEMU 在软件层面，模拟了 CPU 与各种硬件设备（如定时器、串口、磁盘、网卡、显卡）之间的交互，为客户机操作系统，提供了一个完整的、可工作的虚拟硬件平台。

QEMU 的设备模拟，是基于其内部的 **QOM (QEMU Object Model)** 框架，以及 **MMIO (内存映射 I/O)** 和 **中断** 这两个核心机制来构建的。

## 1. QOM：QEMU 对象模型

QOM 是一个用 C 语言实现的、功能强大的面向对象系统。它为 QEMU 提供了一种标准化的、可扩展的方式，来定义、创建和管理各种复杂的“对象”。在 QEMU 中，**每一个虚拟设备，都是一个 QOM 对象**。

**核心概念**: 
*   **类型 (Type)**: 使用 `TypeInfo` 结构体，来定义一个新“类”的属性和方法。`type_register_static` 函数，用于将这个新类型，注册到 QEMU 的类型系统中。
*   **对象 (Object)**: 一个类型的实例。使用 `object_new()` 来创建。
*   **继承 (Inheritance)**: 一个类型，可以继承自另一个父类型，从而复用父类型的属性和方法。
*   **接口 (Interfaces)**: 一个类型，可以实现一个或多个接口，以暴露特定的功能。

通过 QOM，QEMU 将一个复杂的计算机系统，抽象为了一棵由各种设备对象组成的、层级化的树状结构。

## 2. 设备模型的实现

要为 QEMU 添加一个新的虚拟设备，你需要：

### a. 定义设备状态结构体

创建一个 C 结构体，来包含该设备的所有内部状态，例如其控制寄存器、状态寄存器、内部缓冲区等。这个结构体的第一个成员，必须是其父类型（例如 `DeviceState`, `SysBusDevice`, `PCIDevice`）。

```c
// hw/char/my_serial.c

typedef struct {
    SysBusDevice parent_obj;
    MemoryRegion iomem;
    CharBackend chr;

    uint32_t control_reg;
    uint32_t status_reg;
    uint8_t rx_fifo[16];
} MySerialState;
```

### b. 实现 MMIO 读写回调

这是设备与 CPU 交互的核心。你需要实现一组 `read` 和 `write` 函数。当模拟的 CPU，访问到该设备的 MMIO 地址时，QEMU 的内存子系统，就会调用这些函数。

```c
static uint64_t my_serial_read(void *opaque, hwaddr addr, unsigned size) {
    MySerialState *s = opaque;
    // ... 根据地址 addr，返回不同的寄存器值 ...
    if (addr == 0x04) { // Status Register
        return s->status_reg;
    }
    return 0;
}

static void my_serial_write(void *opaque, hwaddr addr, uint64_t value, unsigned size) {
    MySerialState *s = opaque;
    // ... 根据地址 addr 和写入的值 value，改变设备状态 ...
    if (addr == 0x00) { // Data Register
        // 将字符，发送到后端的字符设备 (例如，宿主机的控制台)
        qemu_chr_fe_write_all(&s->chr, &value, 1);
    }
}

static const MemoryRegionOps my_serial_ops = {
    .read = my_serial_read,
    .write = my_serial_write,
    .endianness = DEVICE_NATIVE_ENDIAN,
};
```

### c. 实现设备初始化 (`_init`)

在这个函数中，你需要完成设备的创建和设置。

```c
static void my_serial_init(Object *obj) {
    MySerialState *s = MY_SERIAL(obj);

    // 1. 初始化 MMIO 区域
    memory_region_init_io(&s->iomem, obj, &my_serial_ops, s, "my-serial", 0x1000);
    
    // 2. 将 MMIO 区域，注册到 SysBus 上
    sysbus_init_mmio(SYS_BUS_DEVICE(s), &s->iomem);

    // 3. 初始化字符设备后端
    qemu_char_set_handlers(s->chr, ...);
}
```

### d. 注册设备类型

最后，你需要定义一个 `TypeInfo`，并将你的设备类型，注册到 QOM 中。

```c
static const TypeInfo my_serial_info = {
    .name          = "my-serial",
    .parent        = TYPE_SYS_BUS_DEVICE,
    .instance_size = sizeof(MySerialState),
    .instance_init = my_serial_init,
};

static void my_serial_register_types(void) {
    type_register_static(&my_serial_info);
}

type_init(my_serial_register_types)
```

## 3. 总线与设备树 (Bus & Device Tree)

*   **总线 (Bus)**: 在 QEMU 中，总线（如 `SysBus`, `PCIBus`）是连接 CPU 和设备的“桥梁”。设备，需要将自己“挂载”到相应的总线上，才能被系统所识别。
*   **设备树 (Device Tree)**: 对于 ARM 等平台，QEMU 会在启动时，动态地构建一个设备树。操作系统内核，会通过解析这个设备树，来了解当前系统中有哪些设备、它们的 MMIO 地址是什么、以及它们的中断号是多少，从而加载正确的驱动程序。

## 4. 字符设备与块设备后端 (Chardev & Blockdev Backends)

QEMU 的设备模拟，是分层的。前端的**虚拟设备模型**（如 `pl011` 串口），只负责模拟硬件接口。而实际的 I/O 操作，则被委托给了一个可插拔的**后端**。

*   **字符设备后端 (Chardev)**: 用于处理串行的、基于字符的 I/O。一个虚拟串口的前端，可以连接到多种后端：
    *   `stdio`: 连接到宿主机的标准输入/输出。
    *   `socket`: 连接到一个 TCP 套接字。
    *   `pty`: 连接到一个宿主机的伪终端。

*   **块设备后端 (Blockdev)**: 用于处理对磁盘等块设备的访问。一个虚拟的 IDE 或 SCSI 磁盘控制器，可以连接到多种后端：
    *   `file`: 连接到宿主机上的一个文件（如 `.qcow2`, `.raw` 磁盘镜像）。
    *   `host_device`: 直接连接到宿主机上的一个物理硬盘或分区。

这种**前后端分离**的设计，使得 QEMU 的设备模拟，具有极高的灵活性和可扩展性。

## 总结

QEMU 的设备模拟，是一个基于**面向对象**思想的、高度**模块化**和**分层**的系统。

*   **QOM** 提供了创建和管理设备对象的**基础框架**。
*   **`MemoryRegion`** 和 **MMIO 回调**，是实现 **CPU-设备**交互的**核心机制**。
*   **中断** 是实现设备**异步**通知 CPU 的关键。
*   **总线**和**设备树**，负责将独立的设备，**组织**成一个完整的系统。
*   **前后端分离**的设计，使得虚拟设备，可以与宿主机的各种 I/O 资源，进行灵活的**对接**。

通过这个精巧的系统，QEMU 成功地，在软件中，模拟出了一个丰富多样的、可与真实操作系统交互的“虚拟硬件生态系统”。深入研究 `hw/` 目录下的设备模型源码，是理解现代操作系统，是如何与硬件进行交互的、最直接、最有效的方式。
