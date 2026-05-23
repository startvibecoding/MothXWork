# Session 配置说明

## 概述

VibeCoding GUI 支持在启动时配置以下参数：

- **Provider**: AI 提供商 (如 deepseek-openai, openai, anthropic)
- **Model**: 模型 ID (如 deepseek-v4-flash, gpt-4)
- **Mode**: 运行模式 (plan, agent, yolo)
- **Thinking**: 思考级别 (off, minimal, low, medium, high, xhigh)

## 默认配置

```go
config := &vibecoding.SessionConfig{
    Provider: "deepseek-openai",
    Model:    "deepseek-v4-flash",
    Mode:     "agent",
    Thinking: "medium",
}
```

## 配置方式

### 1. 代码配置

在 `main.go` 中修改默认配置：

```go
config := &vibecoding.SessionConfig{
    Provider: "openai",           // 使用 OpenAI
    Model:    "gpt-4",            // 使用 GPT-4
    Mode:     "yolo",             // YOLO 模式
    Thinking: "high",             // 高思考级别
}
```

### 2. 命令行参数 (待实现)

```bash
./build/bin/vibecoding-gui --provider openai --model gpt-4 --mode yolo --thinking high
```

## 模式说明

| 模式 | 说明 | 文件系统 | 网络 | 沙箱 |
|------|------|----------|------|------|
| **Plan** | 只读分析和规划 | 只读 | ❌ | ✅ |
| **Agent** | 标准模式，受控访问 | 读写 | ❌ | ✅ |
| **YOLO** | 完全访问 | 完全 | ✅ | ❌ |

## 思考级别

| 级别 | 说明 |
|------|------|
| **off** | 关闭思考 |
| **minimal** | 最小思考 |
| **low** | 低思考 |
| **medium** | 中等思考 |
| **high** | 高思考 |
| **xhigh** | 极高思考 |

## Provider 配置

### DeepSeek (默认)

```go
Provider: "deepseek-openai"
Model:    "deepseek-v4-flash"
```

### OpenAI

```go
Provider: "openai"
Model:    "gpt-4"
```

### Anthropic

```go
Provider: "anthropic"
Model:    "claude-3-opus"
```

## 配置验证

启动后，配置会显示在：

1. **标题栏**: 显示当前 provider、model、mode
2. **设置界面**: 显示详细配置信息
3. **状态栏**: 显示连接状态

## 调试

查看 stderr 输出获取配置信息：

```bash
./build/bin/vibecoding-gui 2>&1 | grep -E "Connected|Config"
```

输出示例：

```
Connected to VibeCoding VibeCoding (vdev)
```

## 注意事项

1. **配置在启动时确定**: 配置通过命令行参数传递给 VibeCoding，启动后无法更改
2. **Provider 必须有效**: 确保 provider 和 model 在 VibeCoding 配置中存在
3. **模式影响权限**: 不同模式有不同的文件系统和网络访问权限

## 下一步

1. 添加命令行参数解析
2. 添加配置文件支持
3. 添加运行时配置切换
