# VibeCoding GUI - 快速参考

## 常用命令

```bash
# 进入项目目录
cd prader/vibecoding-gui

# 安装依赖
make setup
# 或
cd frontend && npm install && cd ..

# 启动开发服务器
make dev
# 或
wails dev

# 构建生产版本
make build
# 或
wails build

# 清理构建文件
make clean

# 运行构建后的程序
make run
# 或
./build/bin/vibecoding-gui
```

## 项目结构

```
vibecoding-gui/
├── main.go              # Wails 入口点
├── app.go               # Go 后端逻辑
├── wails.json           # Wails 配置
├── go.mod               # Go 依赖
└── frontend/
    ├── src/
    │   ├── App.tsx      # 主 React 组件
    │   ├── components/  # UI 组件
    │   └── index.css    # 全局样式
    └── wailsjs/         # Wails 绑定
```

## 关键文件

| 文件 | 说明 |
|------|------|
| `main.go` | Wails 应用入口 |
| `app.go` | 后端 API 绑定 |
| `frontend/src/App.tsx` | 前端主组件 |
| `frontend/src/components/ChatArea.tsx` | 聊天区域 |
| `frontend/src/components/Sidebar.tsx` | 侧边栏 |
| `frontend/src/components/InputArea.tsx` | 输入区域 |
| `frontend/src/components/StatusBar.tsx` | 状态栏 |

## 开发流程

1. **修改后端** (Go)
   - 编辑 `app.go` 添加新方法
   - 运行 `wails dev` 自动重载

2. **修改前端** (React)
   - 编辑 `frontend/src/` 下的文件
   - 保存后自动热重载

3. **添加新组件**
   - 在 `frontend/src/components/` 创建新文件
   - 在 `App.tsx` 中导入使用

## 调试技巧

1. **查看后端日志**
   - 终端会显示 Go 日志输出

2. **查看前端日志**
   - 打开浏览器开发者工具 (F12)

3. **调试 Go 代码**
   - 使用 `fmt.Println()` 或日志库

4. **调试 React 代码**
   - 使用 `console.log()` 或 React DevTools

## 常见问题

### Q: 如何添加新的后端方法？
A: 在 `app.go` 中添加方法，然后在 `frontend/wailsjs/go/main/App.js` 中添加绑定。

### Q: 如何修改主题颜色？
A: 编辑 `frontend/src/index.css` 中的 CSS 变量。

### Q: 如何添加新的 Provider？
A: 编辑 `app.go` 中的 `GetProviders()` 方法。

### Q: 如何实现流式响应？
A: 使用 Wails Events:
```go
// 后端
runtime.EventsEmit(ctx, "chat:stream", chunk)

// 前端
EventsOn('chat:stream', (chunk) => {
    // 更新 UI
})
```

## 下一步

1. 阅读 `INTEGRATION.md` 了解如何集成 VibeCoding
2. 阅读 `PLAN.md` 了解完整开发计划
3. 开始实现核心功能！

## 获取帮助

- [Wails 文档](https://wails.io/docs)
- [React 文档](https://react.dev)
- [Tailwind CSS](https://tailwindcss.com)
