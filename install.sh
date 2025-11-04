#!/bin/bash

# --- 配置 ---
REPO_URL="https://github.com/jia6261/mc-g1-lancher.git"
ZIP_DOWNLOAD_URL="https://github.com/jia6261/mc-g1-lancher/archive/refs/heads/main.zip"
MOD_FILE_NAME="minecraft-ai-builder-1.0.0.jar"
MOD_SOURCE_PATH="./$MOD_FILE_NAME" # 假设模组文件与脚本在同一目录
TARGET_DIR="$HOME/AIBuilderLauncher"

# --- 辅助函数 ---

log() {
    local level="$1"
    local message="$2"
    echo "[$(date +'%H:%M:%S')] [$level] $message"
}

check_command() {
    command -v "$1" >/dev/null 2>&1
}

# --- 主安装逻辑 ---

log INFO "--- AI Builder Mod Web 启动器安装程序 (Linux/macOS) ---"
log INFO "目标安装目录: $TARGET_DIR"

# 1. 检查 Git
if check_command git; then
    log SUCCESS "Git 已安装。"
    
    # 使用 Git 克隆
    log INFO "使用 Git 克隆仓库: $REPO_URL"
    if [ -d "$TARGET_DIR" ]; then
        log WARNING "目标目录已存在，正在删除旧目录..."
        rm -rf "$TARGET_DIR"
    fi
    
    if git clone "$REPO_URL" "$TARGET_DIR"; then
        log SUCCESS "仓库克隆成功。"
    else
        log ERROR "Git 克隆失败。请检查网络连接或权限。"
        exit 1
    fi
else
    log WARNING "未检测到 Git。请手动下载启动器核心文件。"
    
    # 提示用户手动下载
    echo ""
    echo "=================================================================="
    echo "请访问以下链接下载启动器核心 ZIP 包："
    echo "$ZIP_DOWNLOAD_URL"
    echo ""
    echo "下载后，请将 ZIP 包中的所有文件解压到以下目录："
    echo "$TARGET_DIR"
    echo "=================================================================="
    echo ""
    
    read -r -p "请确认您已将文件解压到目标目录 (输入 Y 继续): " CONFIRM
    if [[ "$CONFIRM" != "Y" && "$CONFIRM" != "y" ]]; then
        log ERROR "用户取消安装。"
        exit 1
    fi
    
    # 确保目标目录存在
    mkdir -p "$TARGET_DIR"
fi

# 2. 复制模组文件
log INFO "正在复制 AI Builder Mod 文件..."
if [ -f "$MOD_SOURCE_PATH" ]; then
    cp "$MOD_SOURCE_PATH" "$TARGET_DIR/$MOD_FILE_NAME"
    log SUCCESS "模组文件复制成功。"
else
    log WARNING "警告: 模组文件 ($MOD_FILE_NAME) 未找到。请确保它与 install.sh 在同一目录。"
fi

# 3. 安装 Python 依赖
log INFO "正在安装 Python 依赖 (Flask, requests)..."
if check_command pip3; then
    if pip3 install Flask requests; then
        log SUCCESS "Python 依赖安装成功。"
    else
        log ERROR "pip3 安装依赖失败。请确保 Python3 和 pip3 已正确配置。"
        exit 1
    fi
elif check_command pip; then
    log WARNING "未找到 pip3，尝试使用 pip..."
    if pip install Flask requests; then
        log SUCCESS "Python 依赖安装成功。"
    else
        log ERROR "pip 安装依赖失败。请确保 Python 和 pip 已正确配置。"
        exit 1
    fi
else
    log ERROR "未找到 pip 或 pip3 命令。请先安装 Python 3。"
    exit 1
fi

# 4. 启动 Web 启动器
log INFO "正在启动 Web 启动器..."
cd "$TARGET_DIR" || exit 1

# 尝试使用 python3 启动，如果失败则使用 python
if check_command python3; then
    python_cmd="python3"
elif check_command python; then
    python_cmd="python"
else
    log ERROR "未找到 Python 解释器。"
    exit 1
fi

# 在后台启动 Flask 应用
nohup "$python_cmd" app.py > launcher.log 2>&1 &
FLASK_PID=$!

log SUCCESS "Web 启动器已在后台启动 (PID: $FLASK_PID)。"
log INFO "请在浏览器中访问: http://127.0.0.1:5000"

# 尝试自动打开浏览器 (macOS/Linux)
if check_command open; then
    open "http://127.0.0.1:5000"
elif check_command xdg-open; then
    xdg-open "http://127.0.0.1:5000"
fi

log INFO "--- 安装和启动过程完成 ---"
log INFO "要停止启动器，请运行: kill $FLASK_PID"

