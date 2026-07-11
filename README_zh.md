# Mothx GUI (Flutter 版本)

基于 Flutter 和 Dart 构建的 Mothx 桌面客户端。仅通过 HTTP、SSE 和 WebSocket 连接运行中的 `mothx serve`。

## 功能特性

- 🤖 **AI 编程对话**：支持多提供商、多模型切换与直观的对话交互。
- 🔄 **实时流式响应**：极速、流畅的 Stream 消息流渲染。
- 📝 **Markdown 渲染**：完美渲染 Markdown 排版并内置代码块高亮。
- ⚙️ **会话管理**：支持启动时自动创建/恢复会话，持久化各会话的工作目录（CWD）。
- 📡 **Serve 运维数据**：从连接的服务端读取会话历史、用量统计、Cron 任务和实时日志。
- 🎨 **Apple 设计风格**：精美的暗色与亮色模式支持，极富质感。

## 快速开始

### 准备工作

- 已安装 Flutter SDK (3.38.0+)
- 已启动并可通过 HTTP 访问的 `mothx serve` 实例。在 Settings 中配置地址和可选令牌。

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

### 三端构建

请在对应的原生操作系统上执行构建：

```bash
make build          # Linux
make build-windows  # Windows
make build-macos    # macOS
```

Mothx 全局配置读写路径为 `~/.mothx/settings.json`。若该文件不存在，GUI 会读取旧版
`~/.mothx-gui/settings.json`；会话和 UI 元数据仍保存在 `~/.mothx-gui/`。

### 构建 .deb 安装包 (Debian/Ubuntu)

```bash
make deb
```
这将在项目根目录下生成可以直接安装的 `.deb` 安装包。

## 项目架构

- **lib/main.dart**: 客户端主入口和页面基础框架。
- **lib/services/app_state.dart**: 基于 ChangeNotifier 的状态管理器，统一协调 Serve 会话、流式消息、日志、Cron 与统计数据。
- **lib/services/serve_client.dart**: `mothx serve` 的 HTTP、SSE 和 WebSocket 客户端。
- **lib/services/config_service.dart**: 配置管理器，读写 Mothx 全局配置 (`~/.mothx/settings.json`) 和 GUI 偏好 (`~/.mothx-gui/ui.json`)。
- **lib/theme/**: Apple 风格配色及 InheritedWidget 主题向下分发。
- **lib/widgets/**: 模块化的各种界面组件（ChatArea 聊天区, InputArea 输入区, Sidebar 侧边栏, StatusBar 状态栏, 全局/会话设置弹窗等）。
