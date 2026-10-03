# 小草 Mac 浏览器 v1.3.0

同一个 Universal 2 安装包同时支持 Intel Mac 与 Apple silicon Mac。

## 架构支持

- Intel Mac：原生 `x86_64`，包括 Radeon Pro 5600M 的 Intel MacBook Pro。
- Apple silicon Mac：原生 `arm64`，包括 M1、M2、M3、M4 及后续兼容机型。
- 系统会自动选择正确架构，不需要分别下载两个 App，Apple silicon 也不需要 Rosetta。

## 本版改进

- 保留 v1.2.11 的 Touch Bar 全屏键修复。
- 修复播放开始、暂停/继续以及进入/退出视频全屏时 Touch Bar 控件被 WebKit 覆盖的问题。
- 使用 macOS 正式的原生退出全屏键接口。

## 安装

1. 下载并解压 `NewT66y-Mac-Universal-v1.3.0.zip`。
2. 将 `小草 Mac 浏览器.app` 拖入“应用程序”。
3. 首次启动若被 macOS 拦截，请在 Finder 中右键 App，选择“打开”。

本包采用 ad-hoc 签名，未进行 Apple Developer ID 公证。

SHA-256：

```text
5911d9a3444dbeb221e7bfbb77f81a9a41451bbfd1704c4a697f9b42bdd76113  NewT66y-Mac-Universal-v1.3.0.zip
```

---

# Grass Mac Browser v1.3.0

One Universal 2 package supports both Intel and Apple silicon Macs.

## Architecture support

- Native `x86_64` support for Intel Macs, including the Intel MacBook Pro with
  Radeon Pro 5600M.
- Native `arm64` support for Apple silicon Macs, including M1, M2, M3, M4 and
  later compatible models.
- macOS automatically selects the correct architecture. Apple silicon does not
  need Rosetta for this application.

## Changes

- Preserves the v1.2.11 Touch Bar fullscreen-button fix.
- Prevents WebKit from replacing the Touch Bar controls after playback starts,
  pauses, resumes, or enters and exits video fullscreen.
- Uses the supported native macOS exit-fullscreen control.

## Installation

1. Download and extract `NewT66y-Mac-Universal-v1.3.0.zip`.
2. Drag `小草 Mac 浏览器.app` into `Applications`.
3. On first launch, Control-click the app in Finder and choose `Open` if macOS
   blocks it.

The package is ad-hoc signed and is not notarized with an Apple Developer ID.
