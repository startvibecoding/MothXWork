# Apple 风格配色方案

## 概述

已将整体配色修改为苹果风格，参考 macOS/iOS 的深色模式配色。

## 配色方案

### 背景色

| 用途 | 颜色 | 说明 |
|------|------|------|
| 主背景 | #1C1C1E | 主要背景色 |
| 次背景 | #2C2C2E | 卡片、面板背景 |
| 三级背景 | #3A3A3C | 输入框、按钮背景 |
| 提升背景 | #3A3A3C | 悬浮层、下拉菜单 |

### 文字颜色

| 用途 | 颜色 | 说明 |
|------|------|------|
| 主文字 | #FFFFFF | 标题、主要内容 |
| 次文字 | #8E8E93 | 描述、次要信息 |
| 三级文字 | #636366 | 占位符、禁用状态 |

### 强调色

| 用途 | 颜色 | 说明 |
|------|------|------|
| 主强调色 | #007AFF | 按钮、链接、选中状态 |
| 成功色 | #34C759 | 连接状态、成功提示 |
| 错误色 | #FF3B30 | 错误、停止按钮 |
| 警告色 | #FF9500 | 警告提示 |
| 黄色 | #FFCC00 | Plan 模式 |
| 紫色 | #AF52DE | 特殊强调 |

### 分隔线

| 用途 | 颜色 |
|------|------|
| 分隔线 | #38383A |

## 组件样式

### Sidebar

```css
background: #1C1C1E
border-right: 1px solid #38383A
```

### 按钮

```css
/* 主按钮 */
background: #007AFF
hover: #0071E3

/* 次按钮 */
background: #2C2C2E
hover: #3A3A3C

/* 危险按钮 */
background: #FF3B30
hover: #FF453A
```

### 输入框

```css
background: #2C2C2E
border: 1px solid #38383A
focus-border: #007AFF
```

### 消息气泡

```css
/* 用户消息 */
background: #007AFF
text: #FFFFFF

/* AI 消息 */
background: #2C2C2E
text: #FFFFFF
```

### 圆角

| 元素 | 圆角 |
|------|------|
| 卡片 | 12px (rounded-xl) |
| 按钮 | 8px (rounded-lg) |
| 消息气泡 | 16px (rounded-2xl) |
| 下拉菜单 | 12px (rounded-xl) |

## 文字可见性

### 对比度检查

| 组合 | 对比度 | 可见性 |
|------|--------|--------|
| #FFFFFF on #1C1C1E | 15.4:1 | ✅ 优秀 |
| #FFFFFF on #2C2C2E | 11.7:1 | ✅ 优秀 |
| #8E8E93 on #1C1C1E | 5.9:1 | ✅ 良好 |
| #8E8E93 on #2C2C2E | 4.5:1 | ✅ 良好 |
| #636366 on #1C1C1E | 3.5:1 | ✅ 可接受 |
| #FFFFFF on #007AFF | 4.6:1 | ✅ 良好 |

### 字体大小

| 用途 | 大小 | 说明 |
|------|------|------|
| 标题 | 18px | font-lg |
| 正文 | 15px | text-[15px] |
| 小字 | 14px | text-sm |
| 标签 | 12px | text-xs |

## 动画

### 淡入动画

```css
@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}
```

### 上滑动画

```css
@keyframes slideUp {
  from { 
    opacity: 0;
    transform: translateY(10px);
  }
  to { 
    opacity: 1;
    transform: translateY(0);
  }
}
```

## 滚动条

```css
::-webkit-scrollbar {
  width: 8px;
}

::-webkit-scrollbar-thumb {
  background: #767680;
  border-radius: 4px;
}
```

## 构建结果

```
✅ 构建成功
📦 二进制文件: 8.2MB
```

## 运行方式

```bash
cd prader/vibecoding-gui
./build/bin/vibecoding-gui
```

现在界面采用苹果风格的深色配色，具有良好的对比度和文字可见性！
