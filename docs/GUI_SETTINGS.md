# GUI 设置功能说明

## 概述

VibeCoding GUI 支持在运行时通过设置界面修改配置，无需重启应用程序。

## 功能特性

### 1. Provider 选择

支持以下 AI 提供商：

| Provider | 说明 |
|----------|------|
| **deepseek-openai** | DeepSeek (OpenAI API) |
| **deepseek-anthropic** | DeepSeek (Anthropic API) |
| **openai** | OpenAI |
| **anthropic** | Anthropic |

### 2. Model 选择

根据 Provider 自动显示可用模型：

**DeepSeek:**
- DeepSeek-V4-Flash
- DeepSeek-V4-Pro

**OpenAI:**
- GPT-4
- GPT-4 Turbo
- GPT-3.5 Turbo

**Anthropic:**
- Claude 3 Opus
- Claude 3 Sonnet
- Claude 3 Haiku

### 3. Mode 选择

| 模式 | 图标 | 说明 | 文件系统 | 网络 | 沙箱 |
|------|------|------|----------|------|------|
| **Plan** | 🗒️ | 只读分析和规划 | 只读 | ❌ | ✅ |
| **Agent** | 🔧 | 标准模式，受控访问 | 读写 | ❌ | ✅ |
| **YOLO** | 🚀 | 完全访问 | 完全 | ✅ | ❌ |

### 4. Thinking Level 选择

| 级别 | 说明 |
|------|------|
| **Off** | 关闭思考 |
| **Minimal** | 最小思考 |
| **Low** | 低思考 |
| **Medium** | 中等思考 |
| **High** | 高思考 |
| **XHigh** | 极高思考 |

## 使用方法

### 1. 打开设置界面

点击侧边栏底部的 "⚙️ Settings" 按钮。

### 2. 修改配置

1. **选择 Provider**: 从下拉菜单中选择 AI 提供商
2. **选择 Model**: 从下拉菜单中选择模型（自动根据 Provider 更新）
3. **选择 Mode**: 点击相应的模式按钮
4. **选择 Thinking Level**: 从下拉菜单中选择思考级别

### 3. 保存配置

点击 "Save & Restart" 按钮保存配置。应用程序将使用新配置重新创建 ACP 客户端。

## 技术实现

### 后端 API

```go
// GetConfig returns the current configuration
func (a *App) GetConfig() *vibecoding.SessionConfig

// UpdateConfig updates the configuration
func (a *App) UpdateConfig(config *vibecoding.SessionConfig) error
```

### 前端组件

```typescript
interface Config {
  provider: string
  model: string
  mode: string
  thinking: string
}

interface SettingsProps {
  isOpen: boolean
  onClose: () => void
  config: Config
  onConfigChange: (config: Config) => void
}
```

### 配置更新流程

1. 用户在 Settings 界面修改配置
2. 点击 "Save & Restart"
3. 前端调用 `UpdateConfig` API
4. 后端创建新的 ACP 客户端
5. 前端更新状态栏显示

## 注意事项

1. **配置更新会重启 ACP 客户端**: 保存配置时，当前的 ACP 连接会断开并重新建立
2. **Session 不会丢失**: 配置更新不会影响已创建的 session
3. **Provider 必须有效**: 确保选择的 Provider 和 Model 在 VibeCoding 配置中存在
4. **模式影响权限**: 不同模式有不同的文件系统和网络访问权限

## 调试

查看 stderr 输出获取配置更新信息：

```bash
./build/bin/vibecoding-gui 2>&1 | grep -E "Connected|Config"
```

## 下一步

1. 添加配置文件持久化
2. 添加配置验证
3. 添加配置导入/导出
