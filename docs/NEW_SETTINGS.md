# 新的设置功能

## 概述

设置功能已重新设计，分为两个部分：

1. **全局设置** (左下角): 图形化查看 `~/.vibecoding/settings.json` 文件
2. **Session 设置** (右上角): 每个 session 独立的配置，可直接切换

## 功能特性

### 1. 全局设置 (左下角)

点击左下角的 "📄 Edit settings.json" 按钮，打开全局设置界面：

- **查看所有 Providers**: 显示所有配置的 AI 提供商
- **查看所有 Models**: 每个 Provider 下的可用模型，包含上下文窗口信息
- **查看默认设置**: 默认 Provider、Model、Mode、Thinking Level
- **提示编辑**: 显示配置文件路径，提示用户手动编辑

### 2. Session 设置 (右上角)

点击右上角的状态栏，打开 Session 设置下拉菜单：

- **Mode 选择**: Plan, Agent, YOLO
- **Provider 选择**: 从下拉菜单选择 Provider
- **Model 选择**: 从下拉菜单选择 Model
- **Thinking Level**: Off, Minimal, Low, Medium, High, XHigh
- **应用更改**: 点击 "Apply & Restart Session" 按钮应用更改

## 使用方法

### 查看全局设置

1. 点击左下角的 "📄 Edit settings.json"
2. 查看所有配置的 Provider 和 Model
3. 查看默认设置
4. 关闭窗口

### 修改 Session 设置

1. 点击右上角的状态栏
2. 选择 Mode (Plan/Agent/YOLO)
3. 选择 Provider
4. 选择 Model
5. 选择 Thinking Level
6. 点击 "Apply & Restart Session" 按钮

**注意**: 修改 Session 设置会重启当前 session，对话历史将丢失。

## 技术实现

### 全局设置组件

```typescript
// GlobalSettings.tsx
interface GlobalSettingsProps {
  isOpen: boolean
  onClose: () => void
}

export default function GlobalSettings({ isOpen, onClose }: GlobalSettingsProps) {
  // 加载 ~/.vibecoding/settings.json
  // 显示 Provider 和 Model 列表
  // 显示默认设置
}
```

### Session 设置组件

```typescript
// SessionSettings.tsx
interface SessionSettingsProps {
  config: Config
  onConfigChange: (config: Config) => void
}

export default function SessionSettings({ config, onConfigChange }: SessionSettingsProps) {
  // 显示下拉菜单
  // 选择 Mode, Provider, Model, Thinking Level
  // 应用更改
}
```

### 配置更新流程

1. 用户在右上角修改配置
2. 点击 "Apply & Restart Session"
3. 后端关闭现有 ACP 客户端
4. 后端创建新的 ACP 客户端
5. 后端发送 "config:updated" 事件
6. 前端重置状态
7. 前端创建新 session

## 文件结构

```
frontend/src/components/
├── ChatArea.tsx        # 聊天区域
├── InputArea.tsx       # 输入区域
├── Sidebar.tsx         # 侧边栏
├── StatusBar.tsx       # 状态栏
├── GlobalSettings.tsx  # 全局设置 (查看 settings.json)
└── SessionSettings.tsx # Session 设置 (下拉菜单)
```

## 注意事项

1. **全局设置只读**: 全局设置界面只用于查看，不能直接编辑
2. **Session 设置可写**: Session 设置可以直接修改并应用
3. **配置更新会重启 ACP**: 修改 Session 设置会重启 ACP 客户端
4. **Session 会丢失**: 配置更新会创建新的 session，当前对话历史会丢失
5. **Provider 必须有效**: 确保选择的 Provider 在配置文件中存在

## 调试

查看 stderr 输出获取配置信息：

```bash
./build/bin/vibecoding-gui 2>&1 | grep -E "Settings|Provider|Model"
```

## 下一步

1. 添加全局设置编辑功能
2. 添加配置验证
3. 添加配置导入/导出
4. 优化配置更新体验（不丢失对话历史）
