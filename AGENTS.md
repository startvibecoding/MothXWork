# AGENTS.md - VibeCoding GUI (Flutter)

## 概述

使用 Flutter + Dart 跨平台框架构建的 VibeCoding 桌面客户端，通过 stdio (stdin/stdout) JSON-RPC 与 VibeCoding 底层引擎使用 Agent Client Protocol (ACP) 进行安全、高速通信。

## 技术栈

- **前端/运行框架**: Flutter 3.38.0+ / Dart 3.12.2+
- **底层通信**: JSON-RPC over stdio (stdin/stdout) via Agent Client Protocol (ACP)
- **状态管理**: Provider / ChangeNotifier

## 项目结构

```
├── lib/
│   ├── main.dart                  # 应用启动入口、核心布局、权限窗口挂载
│   ├── models/
│   │   └── models.dart            # 会话、消息、提供商和模型等基础实体定义
│   ├── services/
│   │   ├── acp_client.dart        # 纯 Dart 的 ACP 协议引擎 (子进程管理与 I/O 编解码)
│   │   ├── app_state.dart         # 全局状态控制器 (接管消息总线、会话挂载与事件转换)
│   │   └── config_service.dart    # 配置文件序列化与物理路径检索
│   ├── theme/
│   │   └── app_theme.dart         # Apple 设计风格调色板及全局 InheritedWidget 声明
│   └── widgets/
│       ├── chat_area.dart         # 会话消息列表及 Markdown/代码高亮呈现
│       ├── global_settings.dart   # 全局配置对话框 (含提供商、通用、安全审核、沙箱 Tab 页)
│       ├── input_area.dart        # 智能消息输入盒及连接自锁逻辑
│       ├── permission_dialog.dart # 安全操作运行时审批弹窗
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

- **AcpClient (acp_client.dart)**:
  - 接管 `vibecoding acp` 底层二进制的拉起、stdin 写入流 (`_stdin?.add()`) 与 stdout 逐行读取解包监听 (`_handleLine()`)。
  - 将 JSON-RPC 规范定义的通用响应（Response with numeric ID）和服务器端通知（Notification）实时分拣。
  - 通过广播 Stream (`Stream<AcpEvent>`) 将事件分发。

- **AppState (app_state.dart)**:
  - 继承于 `ChangeNotifier`，是全部 UI 渲染的数据生命周期中枢。
  - 挂载 `AcpClient` 的输出，并将底层的 `agent_message_chunk`、`tool_call` 等事件，映射为 UI 上流式展现的 `ChatMessage`。
  - 启动时自动通过 `Directory.current.path` 获取进程所在工作目录，建立默认沙箱连接，确保用户“开箱即用”。

## 会话（Session）与配置存储

- **~/.vibecoding/settings.json**: VibeCoding 引擎官方的全局配置文件（由 GUI 在 Settings 中直接实时读取与同步保存）。
- **~/.vibecoding-gui/sessions.json**: 仅缓存各会话的基础信息（会话随机 ID、别名、选定工作目录 CWD 以及创建时间）。真实的聊天上下文与运行时数据库由 VibeCoding 各会话底层的逻辑自己管理。
