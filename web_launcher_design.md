# Web 启动器架构设计

## 目标
开发一个基于 Python/Flask 的 Web 应用，提供图形化界面来管理 Minecraft 版本、Fabric 环境和 AI Builder Mod 的安装与启动。

## 技术栈
*   **后端**: Python 3.11+, Flask, 核心启动逻辑 (launcher.py)
*   **前端**: HTML5, CSS3, JavaScript (Vanilla 或 React)
*   **通信**: RESTful API (JSON)
*   **部署**: 本地 Web 服务器 (Flask 内置或 Gunicorn)

## 架构概览

```
┌─────────────────────────────────────────────────────┐
│                   Web 浏览器                         │
│  ┌──────────────────────────────────────────────┐   │
│  │      启动器 Web 界面 (HTML/CSS/JS)           │   │
│  │  - 版本选择                                   │   │
│  │  - 模组选择 (AI Builder Mod)                 │   │
│  │  - 安装进度显示                               │   │
│  │  - 启动按钮                                   │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                         ↓ (AJAX/Fetch)
┌─────────────────────────────────────────────────────┐
│              Flask 后端 (Python)                    │
│  ┌──────────────────────────────────────────────┐   │
│  │           API 路由 (Routes)                   │   │
│  │  - GET  /api/versions                         │   │
│  │  - POST /api/setup                            │   │
│  │  - POST /api/install-mod                      │   │
│  │  - POST /api/launch                           │   │
│  │  - GET  /api/status                           │   │
│  └──────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────┐   │
│  │      启动器核心逻辑 (launcher.py)             │   │
│  │  - 版本获取                                   │   │
│  │  - 环境设置                                   │   │
│  │  - 模组安装                                   │   │
│  │  - 游戏启动                                   │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────┐
│            本地文件系统 & Minecraft                  │
│  ~/.minecraft-ai-launcher/                          │
│  ├── 1.20.1/                                        │
│  │   ├── mods/                                      │
│  │   │   ├── fabric-api-...jar                      │
│  │   │   └── minecraft-ai-builder-1.0.0.jar        │
│  │   └── ... (其他 Minecraft 文件)                  │
│  └── 1.19.2/                                        │
│      └── ...                                        │
└─────────────────────────────────────────────────────┘
```

## API 接口设计

### 1. 获取版本列表
**端点**: `GET /api/versions`

**响应**:
```json
{
  "status": "success",
  "versions": [
    {
      "id": "1.20.1",
      "name": "1.20.1",
      "stable": true
    },
    {
      "id": "1.20",
      "name": "1.20",
      "stable": true
    }
  ]
}
```

### 2. 设置环境
**端点**: `POST /api/setup`

**请求体**:
```json
{
  "mc_version": "1.20.1"
}
```

**响应**:
```json
{
  "status": "success",
  "message": "Minecraft 1.20.1 Fabric 环境设置完成",
  "install_dir": "~/.minecraft-ai-launcher/1.20.1"
}
```

### 3. 安装模组
**端点**: `POST /api/install-mod`

**请求体**:
```json
{
  "mc_version": "1.20.1",
  "install_ai_mod": true
}
```

**响应**:
```json
{
  "status": "success",
  "message": "AI Builder Mod 已安装",
  "mod_path": "~/.minecraft-ai-launcher/1.20.1/mods/minecraft-ai-builder-1.0.0.jar"
}
```

### 4. 启动游戏
**端点**: `POST /api/launch`

**请求体**:
```json
{
  "mc_version": "1.20.1"
}
```

**响应**:
```json
{
  "status": "success",
  "message": "启动说明已生成",
  "launch_instructions": "请使用官方 Minecraft 启动器..."
}
```

### 5. 获取安装状态
**端点**: `GET /api/status/<mc_version>`

**响应**:
```json
{
  "status": "success",
  "mc_version": "1.20.1",
  "installed": true,
  "fabric_installed": true,
  "fabric_api_installed": true,
  "ai_mod_installed": true
}
```

## 前端页面设计

### 主页面布局
1.  **顶部导航栏**: 应用标题和快速链接
2.  **版本选择区域**: 显示可用的 Minecraft 版本列表
3.  **安装步骤区域**: 
    - 步骤 1: 选择版本
    - 步骤 2: 设置 Fabric 环境
    - 步骤 3: 选择模组 (AI Builder Mod)
    - 步骤 4: 启动游戏
4.  **进度显示区域**: 实时显示安装进度
5.  **日志输出区域**: 显示详细的操作日志

## 工作流程

**用户操作流程**:

1.  用户打开 Web 启动器 (`http://localhost:5000`)。
2.  前端加载版本列表 (调用 `GET /api/versions`)。
3.  用户选择 Minecraft 版本 (例如 `1.20.1`)。
4.  用户点击 **"设置环境"** 按钮。
   - 前端发送 `POST /api/setup` 请求。
   - 后端下载 Fabric Installer 并运行。
   - 前端显示进度条。
5.  用户勾选 **"安装 AI Builder Mod"** 复选框。
6.  用户点击 **"安装模组"** 按钮。
   - 前端发送 `POST /api/install-mod` 请求。
   - 后端复制模组文件到 `mods` 文件夹。
7.  用户点击 **"启动游戏"** 按钮。
   - 前端发送 `POST /api/launch` 请求。
   - 后端返回启动说明。
   - 前端显示详细的启动步骤。

## 总结

此架构提供了一个模块化、可扩展的 Web 启动器框架，前端和后端分离，便于维护和升级。后续可以轻松集成更多功能，如模组市场、配置管理等。

