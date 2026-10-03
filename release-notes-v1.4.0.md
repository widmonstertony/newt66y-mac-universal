# 小草 Mac 浏览器 v1.4.0

同一个 Universal 2 安装包同时支持 Intel Mac 与 Apple silicon Mac。

## 本版改进

- 视频播放切换为真正的 macOS AVKit 原生播放器，全屏后不再残留网页播放器的中央三角形。
- Touch Bar 保留 Safari 风格的原生播放进度条；全屏键在播放及全屏状态下持续显示，并可再次按下退出全屏。
- 退出原生全屏时恢复原来的网页、视频进度、滚动位置和浏览器返回栈，不再停留在独立播放器页面。
- 修复同一视频出现两个下载按钮的问题，每个视频只保留一个 VidCatch 下载入口。
- 保留触控板左右滑动历史导航及此前的网站兼容性修复。

## 架构支持

- Intel Mac：原生 `x86_64`，包括 Radeon Pro 5600M 的 Intel MacBook Pro。
- Apple silicon Mac：原生 `arm64`，包括 M1、M2、M3、M4 及后续兼容机型。
- 系统会自动选择正确架构，Apple silicon 不需要 Rosetta。

## 安装

1. 下载并解压 `NewT66y-Mac-Universal-v1.4.0.zip`。
2. 将 `小草 Mac 浏览器.app` 拖入“应用程序”。
3. 首次启动若被 macOS 拦截，请在 Finder 中右键 App，选择“打开”。

本包采用 ad-hoc 签名，未进行 Apple Developer ID 公证。

SHA-256：

```text
6f7b6289edf45421abcbd5a0cbb78cc43dfa2d791adaad66d3f233afbf096c74  NewT66y-Mac-Universal-v1.4.0.zip
```

---

# Grass Mac Browser v1.4.0

One Universal 2 package supports Intel and Apple silicon Macs.

## Changes

- Uses a true native macOS AVKit player so the webpage's central play overlay no longer remains over fullscreen video.
- Keeps the Safari-style native Touch Bar scrubber and preserves the fullscreen toggle during playback and fullscreen; press it again to exit.
- Restores the original webpage, playback position, scroll position, and browser back stack after native fullscreen exits.
- Removes the duplicate download control so each video has one VidCatch download button.
- Preserves trackpad history navigation and the previous website compatibility fixes.

## Architecture support

- Native `x86_64` for Intel Macs, including the Intel MacBook Pro with Radeon Pro 5600M.
- Native `arm64` for Apple silicon Macs, including M1, M2, M3, M4 and later compatible models.
- macOS selects the correct architecture automatically; Rosetta is not required on Apple silicon.

## Installation

1. Download and extract `NewT66y-Mac-Universal-v1.4.0.zip`.
2. Drag `小草 Mac 浏览器.app` into `Applications`.
3. If macOS blocks the first launch, Control-click the app in Finder and choose `Open`.

The package is ad-hoc signed and is not notarized with an Apple Developer ID.
