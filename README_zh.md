# Mothx GUI (Flutter 版本)

基于 Flutter 和 Dart 构建的 Mothx 桌面客户端。通过 Agent Client Protocol (ACP) 协议，使用 stdio (stdin/stdout) JSON-RPC 与 Mothx 底层引擎进行高效通信。

## 功能特性

- 🤖 **AI 编程对话**：支持多提供商、多模型切换与直观的对话交互。
- 🔄 **实时流式响应**：极速、流畅的 Stream 消息流渲染。
- 📝 **Markdown 渲染**：完美渲染 Markdown 排版并内置代码块高亮。
- ⚙️ **会话管理**：支持启动时自动创建/恢复会话，持久化各会话的工作目录（CWD）。
- 🛡️ **运行安全控制**：当 AI 尝试执行 Bash 命令或写文件时，通过可视化的权限审批弹窗让您实时确认或拒绝。
- 🎨 **Apple 设计风格**：精美的暗色与亮色模式支持，极富质感。

## 快速开始

### 准备工作

- 已安装 Flutter SDK (3.38.0+)
- 已安装 Mothx 命令行可执行文件（在系统 PATH 中，或位于 `~/go/bin/mothx`）

### 构建与运行

```bash
# 获取 Dart 依赖
flutter pub get

# 启动开发调试模式 (Linux)
make dev

# 编译 Linux 平台的 Release 包
make build

# 运行编译好的 Release 可执行程序
make run

# 清理构建产物
make clean
```

### 构建 .deb 安装包 (Debian/Ubuntu)

```bash
make deb
```
这将在项目根目录下生成可以直接安装的 `.deb` 安装包。

## 项目架构

- **lib/main.dart**: 客户端主入口，页面基础框架及权限确认弹窗遮罩。
- **lib/services/app_state.dart**: 基于 ChangeNotifier 的状态管理器，统一协调会话切换、配置加载、通信状态与消息更新。
- **lib/services/acp_client.dart**: 纯 Dart 实现的 ACP (JSON-RPC) 客户端，封装了底层 stdin 写入与 stdout 实时流监听。
- **lib/services/config_service.dart**: 配置管理器，读写 Mothx 全局配置 (`~/.mothx/settings.json`) 以及 GUI 的会话缓存 (`~/.mothx-gui/sessions.json`)。
- **lib/theme/**: Apple 风格配色及 InheritedWidget 主题向下分发。
- **lib/widgets/**: 模块化的各种界面组件（ChatArea 聊天区, InputArea 输入区, Sidebar 侧边栏, StatusBar 状态栏, 全局/会话设置弹窗等）。
