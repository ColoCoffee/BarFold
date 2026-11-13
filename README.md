# BarFold

BarFold 是一个原生 macOS 菜单栏工具，可以折叠分隔线左侧的图标。使用 Swift 和 AppKit 编写，无需辅助功能或屏幕录制权限。

## 下载与使用

1. 从 [GitHub Releases](https://github.com/ColoCoffee/BarFold/releases) 下载 `BarFold-v1.1.0-universal.zip`，解压并打开 `BarFold.app`。
2. 在屏幕右上方找到竖线和箭头。按住 **⌘** 拖动竖线或其他图标，把要隐藏的图标放在竖线左边，箭头留在右边。
3. 左键点箭头切换折叠状态。右键可打开控制窗口或退出。

首次打开会显示控制窗口。菜单栏空间不足时，从访达再次打开 BarFold 即可呼出控制窗口。部分系统图标由 macOS 管理，能否拖动取决于该图标。

如果展开后仍看不到竖线，从访达再次打开 BarFold，再点控制窗口里的 **重置竖线位置**。此功能会展开图标，并把竖线移回箭头左侧。首发 v1.1.0 的安装包需从当前源码重新构建才有此按钮。

发行包使用临时签名，尚未经过 Apple 公证。首次打开下载的副本时，Gatekeeper 可能拦截。也可以从源码在本机编译。

## 兼容性

构建目标为 **macOS 13 Ventura 或更新版本**。通用应用包包含 `arm64`（Apple Silicon）和 `x86_64`（Intel）。

| 环境 | 验证结果 |
| --- | --- |
| macOS 15.7.9 · Apple Silicon · 刘海屏 | 实机验证启动、图标可见性、折叠与展开、控制窗口 |
| macOS 13、14、26、27 | 部署目标允许安装，尚无对应版本的桌面实测 |
| Intel Mac | 二进制切片、部署目标和签名已检查，尚无 Intel 实机验证 |

## 从源码构建

需要 Apple Command Line Tools。运行以下命令会生成 `dist/BarFold.app`。

```sh
xcode-select --install
./build.sh
open dist/BarFold.app
```

`build.sh` 也接受一个可选的应用包输出路径。

## 实现

BarFold 注册两个 AppKit 状态项。箭头负责切换，竖线负责分组。折叠时把分隔项变成宽的空白项，利用 macOS 自己的布局将左侧图标移出可见区域。展开时恢复原宽度。可见空间仍由 macOS 决定，取决于屏幕、刘海和当前应用菜单。
