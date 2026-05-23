# 类型修复说明

## 问题描述

TypeScript 编译错误：

```
Argument of type 'Config' is not assignable to parameter of type 'SessionConfig'.
Property 'cwd' is missing in type 'Config' but required in type 'SessionConfig'.
```

## 原因

Go 后端的 `SessionConfig` 结构体包含 `cwd` 字段：

```go
type SessionConfig struct {
    Cwd       string `json:"cwd"`
    Provider  string `json:"provider,omitempty"`
    Model     string `json:"model,omitempty"`
    Mode      string `json:"mode,omitempty"`
    Thinking  string `json:"thinking,omitempty"`
}
```

但前端的 `Config` 接口缺少 `cwd` 字段。

## 修复

### 1. 更新前端 Config 接口

```typescript
// 修复前
interface Config {
  provider: string
  model: string
  mode: string
  thinking: string
}

// 修复后
interface Config {
  cwd: string
  provider: string
  model: string
  mode: string
  thinking: string
}
```

### 2. 更新初始状态

```typescript
// 修复前
const [config, setConfig] = useState<Config>({
  provider: 'deepseek-openai',
  model: 'deepseek-v4-flash',
  mode: 'agent',
  thinking: 'medium'
})

// 修复后
const [config, setConfig] = useState<Config>({
  cwd: '',
  provider: 'deepseek-openai',
  model: 'deepseek-v4-flash',
  mode: 'agent',
  thinking: 'medium'
})
```

## 影响的文件

- `frontend/src/App.tsx`
- `frontend/src/components/Settings.tsx`

## 验证

```bash
wails build
```

构建成功：

```
✅ Generating bindings
✅ Installing frontend dependencies
✅ Compiling frontend
✅ Compiling application
✅ Packaging application
Built 'build/bin/vibecoding-gui' in 37.817s
```

## 下一步

1. 测试 GUI 设置功能
2. 验证配置更新
3. 测试完整的消息流程
