# 问题修复说明

## 问题 1: `unknown flag: --acp`

**原因**: VibeCoding 的 ACP 模式是子命令，不是标志

**修复**:
```go
// 修复前
client.cmd = exec.CommandContext(ctx, vibecodingPath, "--acp")

// 修复后
client.cmd = exec.CommandContext(ctx, vibecodingPath, "acp")
```

## 问题 2: `No listeners for event 'chat:event'`

**原因**: 事件监听器在发送消息时可能还未设置好

**修复**: 
- 确保 EventsOn 在组件挂载时立即设置
- 添加 console.log 用于调试
- 正确处理 EventsOn 的返回值（取消订阅函数）

```typescript
// 修复后
const setupEventListeners = () => {
  const unsubscribe = EventsOn('chat:event', (event: any) => {
    console.log('Received chat event:', event)
    handleChatEvent(event)
  })
  return unsubscribe
}

useEffect(() => {
  const unsubscribe = setupEventListeners()
  initSession()
  return () => unsubscribe()
}, [])
```

## 问题 3: `panic: send on closed channel`

**原因**: 在 Chat 函数中，当 ctx.Done() 时，外层 goroutine 可能已经关闭了 events channel，但内层 goroutine 还在尝试发送

**修复**: 使用 done channel 协调 goroutine 生命周期

```go
// 修复后
go func() {
    defer close(events)
    
    done := make(chan struct{})
    defer close(done)
    
    // Listen for ACP events
    go func() {
        for {
            select {
            case event, ok := <-am.client.Events():
                if !ok {
                    return
                }
                // ... handle event
                select {
                case events <- chatEvent:
                case <-done:
                    return
                case <-ctx.Done():
                    return
                }
            case <-done:
                return
            case <-ctx.Done():
                return
            }
        }
    }()
    
    // Send prompt
    // ...
}()
```

## 验证

```bash
# 重新构建
go build -o build/bin/vibecoding-gui .

# 运行测试
./test-acp.sh

# 运行应用程序
./build/bin/vibecoding-gui
```

## 调试技巧

1. **查看控制台日志**: 前端会输出 `Received chat event:`
2. **查看 stderr**: VibeCoding 的 stderr 会输出到控制台
3. **使用浏览器开发者工具**: F12 查看网络请求和日志

## 下一步

1. 测试完整的消息流程
2. 验证流式响应
3. 测试会话切换
