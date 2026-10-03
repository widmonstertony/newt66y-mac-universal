# 小草 Mac 浏览器 / Grass Mac Browser

一个原生 macOS WebKit 客户端，同一个 Universal 2 安装包同时支持 Intel Mac
与 Apple silicon Mac。它不是把 iOS IPA 直接转换为 macOS 程序，而是针对 macOS
重新实现的客户端。

A native macOS WebKit client distributed as one Universal 2 application for
both Intel and Apple silicon Macs. This is a macOS implementation, not a direct
conversion of an iOS IPA.

## 系统要求 / Requirements

- macOS 12.0 或更高版本 / macOS 12.0 or later.
- Intel Mac：原生 `x86_64`，包括 Radeon Pro 5600M 的 Intel MacBook Pro。
- Apple silicon Mac：原生 `arm64`，支持 M1、M2、M3、M4 及后续兼容机型。
- Apple silicon 会直接运行 ARM 版本，不需要 Rosetta。
- One ZIP works on both architectures; macOS automatically selects the correct
  executable slice.

## 中文安装说明

### 首次安装

1. 从 [GitHub Releases](https://github.com/widmonstertony/newt66y-mac-universal/releases/latest)
   下载 `NewT66y-Mac-Universal-v1.4.0.zip`。
2. 可选但推荐：在终端校验下载文件：

   ```bash
   shasum -a 256 NewT66y-Mac-Universal-v1.4.0.zip
   ```

   正确结果应为：

   ```text
   6f7b6289edf45421abcbd5a0cbb78cc43dfa2d791adaad66d3f233afbf096c74
   ```

3. 双击 ZIP 解压。
4. 将 `小草 Mac 浏览器.app` 拖入 Finder 的“应用程序”文件夹。不要长期从 ZIP
   或“下载”文件夹里运行。
5. 第一次启动时，在 Finder 中右键 `小草 Mac 浏览器.app`，选择“打开”，然后在
   对话框中再次选择“打开”。
6. 如果 macOS 仍然阻止启动，请打开“系统设置 → 隐私与安全”，在安全提示旁选择
   “仍要打开”。不需要关闭 Gatekeeper。

本 App 使用 ad-hoc 签名，没有 Apple Developer ID 公证，因此首次打开时出现上述
确认属于预期行为。

### 从“小草 Intel 浏览器”升级

1. 先退出旧版 App。
2. 将新版 `小草 Mac 浏览器.app` 拖入“应用程序”。
3. 确认新版可以正常启动后，可以移除旧的 `小草 Intel 浏览器.app`，避免以后打开
   错版本。新版仍沿用相同 Bundle ID。

### 验证 Universal 2 架构

安装后可以运行：

```bash
file "/Applications/小草 Mac 浏览器.app/Contents/MacOS/NewT66yIntel"
```

输出应同时包含 `x86_64` 和 `arm64`。

## English installation guide

### First installation

1. Download `NewT66y-Mac-Universal-v1.4.0.zip` from
   [GitHub Releases](https://github.com/widmonstertony/newt66y-mac-universal/releases/latest).
2. Optionally verify the download in Terminal:

   ```bash
   shasum -a 256 NewT66y-Mac-Universal-v1.4.0.zip
   ```

   Expected SHA-256:

   ```text
   6f7b6289edf45421abcbd5a0cbb78cc43dfa2d791adaad66d3f233afbf096c74
   ```

3. Double-click the ZIP to extract it.
4. Drag `小草 Mac 浏览器.app` into the Finder `Applications` folder. Do not
   keep running it from the ZIP or Downloads folder.
5. For the first launch, Control-click or right-click the app in Finder, choose
   `Open`, then choose `Open` again in the confirmation dialog.
6. If macOS still blocks the app, open `System Settings → Privacy & Security`
   and select `Open Anyway` beside the security message. You do not need to
   disable Gatekeeper.

The application is ad-hoc signed and is not notarized with an Apple Developer
ID, so a first-launch confirmation is expected.

### Upgrading from “小草 Intel 浏览器”

1. Quit the old application.
2. Move the new `小草 Mac 浏览器.app` into `Applications`.
3. After confirming that v1.4.0 opens correctly, you may remove the old
   `小草 Intel 浏览器.app` to avoid launching the wrong copy. The new app keeps
   the same bundle identifier.

### Verify the Universal 2 architectures

After installation, run:

```bash
file "/Applications/小草 Mac 浏览器.app/Contents/MacOS/NewT66yIntel"
```

The result should list both `x86_64` and `arm64`.

## 功能 / Features

- 按原 iOS 版布局重建首页和底部导航。
- 原生 WKWebView、触控板历史手势、后退、前进、刷新和站内导航。
- Safari 风格的 AVKit Touch Bar 播放、进度、画中画和全屏控制。
- 真正使用 AVKit 原生视频解码与播放，网页播放器的中央播放遮罩不会留在全屏画面上。
- Touch Bar 全屏键在播放及全屏状态下保持可见，并切换为退出全屏。
- 退出全屏后恢复原网页、视频进度、滚动位置和返回栈。
- 每个视频只显示一个 VidCatch 下载按钮。
- 原生视频全屏，以及原生全屏失败时的纯视频影院模式。
- VidCatch companion 下载按钮；普通文件下载保存到 `~/Downloads`。
- Recreated iOS-style home screen and bottom navigation.
- Native WKWebView navigation and trackpad history gestures.
- Safari-style AVKit Touch Bar playback, scrubber, Picture in Picture and
  fullscreen controls.
- Native AVKit playback removes the webpage's stale central play overlay.
- The Touch Bar fullscreen toggle remains available during playback and
  fullscreen, and changes to an exit-fullscreen control.
- Exiting fullscreen restores the original webpage, playback position, scroll
  position, and browser back stack.
- Exactly one VidCatch download button is shown per video.
- Native video fullscreen with a video-only fallback mode.

## 视频下载 / Video downloads

右下角下载按钮使用 VidCatch v0.3.0 的本地 companion：

1. 安装 VidCatch v0.3.0。
2. 运行其 `Install VidCatch.command`。
3. 确认本地 companion 正在运行。
4. 先播放视频，再点击客户端右下角的 `⇩`。

The bottom-right download button requires the local VidCatch v0.3.0 companion.
Install and start the companion, begin video playback, then press `⇩`. Downloads
are saved to `~/Downloads`. Intel Macs also need working Python 3 and FFmpeg
installations for the companion.

## 本地构建 / Local build

需要 Xcode Command Line Tools / Requires Xcode Command Line Tools:

```bash
./build.sh
```

输出 / Output:

```text
dist/小草 Mac 浏览器.app
dist/NewT66y-Mac-Universal-v1.4.0.zip
```

构建脚本会验证主程序同时包含 `x86_64` 和 `arm64`，并对 App 进行 ad-hoc 签名。

The build script verifies both `x86_64` and `arm64` slices and applies an ad-hoc
signature to the app bundle.

## 说明与边界 / Notice and scope

本项目与 NewT66y、小草、草榴社区、PlayCover 或相关网站没有官方关联，也不绕过
网站登录、访问控制、DRM 或其他技术措施。公开源码或构建工具不应包含未经授权的
IPA、视频内容或第三方专有素材。

This project is not affiliated with NewT66y, Grass, the related community,
PlayCover, or any associated website. It does not bypass authentication,
access controls, DRM, or similar technical protections. Public source and build
tools should not redistribute unauthorized IPAs, videos, or proprietary assets.
