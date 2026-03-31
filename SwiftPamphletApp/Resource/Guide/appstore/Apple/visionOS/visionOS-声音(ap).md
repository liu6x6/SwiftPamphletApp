# visionOS 空间音频 (Spatial Audio)

在空间计算时代，声音不仅仅是“左声道”和“右声道”的区分，而是具备**精确的物理位置、环境反射和方向感**。优秀的音频设计能欺骗大脑，让虚拟物体显得真实存在。

## 1. 空间音频的原理

Vision Pro 硬件搭载了极其先进的音频追踪技术（Audio Ray Tracing）。它利用外部传感器扫描你所在房间的物理形状和材质（如玻璃窗反弹声音大，地毯吸音）。
当你播放一个与虚拟物体绑定的声音时，系统会实时计算声波在当前真实房间里的反射和衰减，然后将渲染后的声音传递给扬声器。

## 2. 声音的三大层级

在 visionOS 应用中，Apple 建议将音频分为三种类型，并使用不同的 API 播放：

### UI 交互音效 (UI Sounds)
*   **用途**：按钮点击、警告提示、视图展开。
*   **特性**：不需要有明显的 3D 空间感，但要听起来清晰、不干扰环境。
*   **实现**：通常沿用传统的 \`AVAudioPlayer\` 或是系统自带的触觉反馈/提示音。

### 空间音效 (Spatial Audio)
*   **用途**：一个虚拟瀑布模型发出的水流声，或者一只虚拟小鸟飞过头顶的鸣叫。
*   **特性**：声音的来源完全与 3D 物体的位置（Transform）绑定。当你转头或走近模型时，声音的方向和音量会自然变化。
*   **实现**：使用 **RealityKit** 的 \`AudioFileResource\` 和 \`SpatialAudioComponent\`。

```swift
// 在 RealityKit 实体上挂载空间音频组件
let audioEntity = Entity()
// 开启环境混响和衰减
let audioComponent = SpatialAudioComponent(directivity: .beam(focus: 0.5))
audioEntity.components.set(audioComponent)

// 加载并播放
let resource = try await AudioFileResource(named: "BirdChirp.caf")
let controller = audioEntity.prepareAudio(resource)
controller.play()
```

### 环境音 (Ambient Sound)
*   **用途**：完全沉浸空间（Immersive Space）中的背景音，例如雨林的白噪音。
*   **特性**：声音应该包围用户，但没有特定的点声源，随着用户头部的转动，声场会稳定在虚拟环境中。
*   **实现**：使用 \`PHASE\` 框架 (Physical Audio Spatialization Engine) 进行极高自由度的环境音场构建。

## 3. 设计建议

1.  **静音是默认状态**：不要让应用一启动就播放巨大背景音乐。用户可能同时在使用多个空间 App。
2.  **视觉与听觉同步**：如果你展示了一个 3D 的警车，警笛的声音方向必须和警车的视觉位置严丝合缝，否则会导致严重的认知错乱和晕动症。
3.  **使用 Reality Composer Pro 调试**：在开发阶段，利用 Reality Composer Pro 的可视化界面为模型添加 Audio 组件是最高效的，你可以在编辑器里直观地拉扯声音衰减的半径球体。
