# AGENTS.md - VibeCoding GUI (Flutter)

## 概述

使用 Flutter + Dart 跨平台框架构建的 VibeCoding 桌面客户端，仅通过 `mothx serve` 的 HTTP、SSE 和 WebSocket API 通信。

## 技术栈

- **前端/运行框架**: Flutter 3.38.0+ / Dart 3.12.2+
- **底层通信**: HTTP REST、SSE 流式响应和 WebSocket 日志流 via `mothx serve`
- **状态管理**: Provider / ChangeNotifier

## 项目结构

```
├── lib/
│   ├── main.dart                  # 应用启动入口、核心布局、权限窗口挂载
│   ├── models/
│   │   └── models.dart            # 会话、消息、提供商和模型等基础实体定义
│   ├── services/
│   │   ├── serve_client.dart       # Serve HTTP/SSE/WebSocket 客户端
│   │   ├── app_state.dart         # 全局状态控制器 (会话、流式消息、日志、Cron、统计)
│   │   └── config_service.dart    # 配置文件序列化与物理路径检索
│   ├── theme/
│   │   └── app_theme.dart         # Apple 设计风格调色板及全局 InheritedWidget 声明
│   └── widgets/
│       ├── chat_area.dart         # 会话消息列表及 Markdown/代码高亮呈现
│       ├── global_settings.dart   # 全局配置对话框 (含提供商、通用、安全审核、沙箱 Tab 页)
│       ├── input_area.dart        # 智能消息输入盒及连接自锁逻辑
│       ├── session_settings.dart   # 各会话专有提供商、模型与思考级别切换浮窗
│       ├── sidebar.dart           # 会话列表及新建、删除右键菜单
│       └── status_bar.dart        # 底部后台进程连接状态和计数器
├── linux/                         # Linux 桌面专属底层平台包装层
├── test/                          # 单元及 UI 自动化测试
├── Makefile                       # 开发、运行与 .deb 构建总控文件
├── pubspec.yaml                   # Dart 依赖树定义
└── README.md                      # 项目中英文引导指南
```

## 核心架构

- **ServeClient (serve_client.dart)**:
  - 调用 `/api/sessions`、`/api/stats/*`、`/api/cron` 等 REST 接口管理数据。
  - 调用 `/v1/chat/completions` 并解析 SSE 事件，实现会话创建和流式消息。
  - 连接 `/ws/logs` 获取实时日志。

- **AppState (app_state.dart)**:
  - 继承于 `ChangeNotifier`，是全部 UI 渲染的数据生命周期中枢。
  - 挂载 `ServeClient` 输出，将流式消息和工具事件映射为 UI 上的 `ChatMessage`。
  - 启动时读取已保存的 Serve 地址并连接；首次发送消息时由服务端创建会话。

## 会话（Session）与配置存储

- **~/.mothx/settings.json**: Mothx 引擎官方的全局配置文件（由 GUI 在 Settings 中直接实时读取与同步保存）。
- **~/.mothx-gui/ui.json**: GUI 专有的主题偏好。会话列表、历史和运行时状态由 `mothx serve` 管理。
