# AI Builder Mod Web 启动器核心

这是一个基于 Python/Flask 的 Web 应用程序，作为 **AI Builder Mod** 的跨平台启动器核心。它旨在自动化 Minecraft Fabric 环境的安装和模组部署过程。

## 功能特性

*   **跨平台安装**：提供 `install.ps1` (Windows) 和 `install.sh` (Linux/macOS) 脚本，自动化环境设置。
*   **Web UI**：通过浏览器提供图形化界面，管理 Minecraft 版本和模组安装。
*   **核心逻辑**：自动化下载 Fabric Loader、Fabric API，并部署 AI Builder Mod。
*   **AI Builder Mod**：包含核心模组文件 `minecraft-ai-builder-1.0.0.jar`，该模组允许玩家通过 `/ai <指令>` 来驱动 AI 在游戏中建造方块。

## 包含文件

| 文件/目录 | 描述 |
| :--- | :--- |
| `app.py` | Flask 后端主程序，实现 API 路由和启动逻辑。 |
| `templates/` | 包含 `index.html`，Web 界面的 HTML 模板。 |
| `static/` | 包含 `css/style.css` 和 `js/app.js`，Web 界面的样式和交互逻辑。 |
| `install.ps1` | Windows 自动化安装和启动脚本。 |
| `install.sh` | Linux/macOS 自动化安装和启动脚本。 |
| `minecraft-ai-builder-1.0.0.jar` | AI Builder Mod 的最终版本。 |
| `web_launcher_design.md` | 启动器架构设计文档。 |
| `.gitignore` | Git 忽略文件配置。 |

## 如何使用

### 1. Windows 用户

1.  确保您的系统安装了 **Python 3**。
2.  右键点击 `install.ps1`，选择 **“使用 PowerShell 运行”**。
3.  脚本将自动安装依赖、复制文件，并在后台启动 Web 服务器。
4.  浏览器将自动打开 `http://127.0.0.1:5000`。

### 2. Linux/macOS 用户

1.  确保您的系统安装了 **Python 3**。
2.  打开终端，进入项目目录。
3.  赋予执行权限：`chmod +x install.sh`
4.  运行脚本：`./install.sh`
5.  浏览器将自动打开 `http://127.0.0.1:5000`。

### 3. Web 界面操作

在浏览器中，您可以：

1.  选择 Minecraft 版本。
2.  点击 **“设置环境”** 按钮来安装 Fabric Loader 和 Fabric API。
3.  勾选并安装 **AI Builder Mod**。
4.  获取详细的启动说明。

