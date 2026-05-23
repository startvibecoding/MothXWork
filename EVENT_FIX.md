# ACP 事件格式修复

## 问题描述

VibeCoding ACP 发送的事件格式与 GUI 期望的格式不匹配。

## VibeCoding 实际事件格式

```json
{
  "jsonrpc": "2.0",
  "method": "session/update",
  "params": {
    "sessionId": "386a12b3",
    "update": {
      "sessionUpdate": "agent_thought_chunk",
      "content": {
        "type": "text",
        "text": "Hello"
      }
    }
  }
}
```

## 事件类型映射

| VibeCoding 事件类型 | GUI 事件类型 | 说明 |
|---------------------|--------------|------|
| `agent_thought_chunk` | `content` | 思考过程 |
| `agent_message_chunk` | `content` | 消息内容 |
| `content` | `content` | 通用内容 |
| `tool_call` | `toolCall` | 工具调用开始 |
| `tool_call_update` | `toolCallUpdate` | 工具调用更新 |
| `status` | `status` | 状态更新 |

## 修复内容

### 1. 解析嵌套结构

```go
// 修复前
var update sessionUpdate
json.Unmarshal(params, &update)

// 修复后
var notification struct {
    SessionID string `json:"sessionId"`
    Update    struct {
        SessionUpdate string      `json:"sessionUpdate"`
        Content       *contentBlock `json:"content,omitempty"`
        // ...
    } `json:"update"`
}
json.Unmarshal(params, &notification)
```

### 2. 处理多种事件类型

```go
switch update.SessionUpdate {
case "agent_thought_chunk", "agent_message_chunk":
    // 转换为 content 事件
    event.Type = "content"
    event.Content = update.Content.Text
case "tool_call":
    // 工具调用开始
case "tool_call_update":
    // 工具调用更新
    event.Type = "toolCallUpdate"
case "status":
    // 状态更新
}
```

### 3. 前端事件处理

```typescript
switch (event.type) {
    case 'content':
        appendToStreamingMessage(event.content)
        break
    case 'toolCall':
        // 显示工具调用
        break
    case 'toolCallUpdate':
        if (event.data?.status === 'completed' && event.content) {
            // 显示工具结果
        }
        break
}
```

## 调试输出

添加了调试日志：

```
[ACP EVENT] method=session/update
[ACP EVENT SEND] type=content content_len=50
```

## 验证

```bash
# 重新构建
go build -o build/bin/vibecoding-gui .

# 运行应用程序
./build/bin/vibecoding-gui

# 查看 stderr 输出获取调试信息
```

## 下一步

1. 测试完整的消息流程
2. 验证流式响应
3. 测试工具调用显示
