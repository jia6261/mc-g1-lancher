<#
.SYNOPSIS
    AI Builder Mod Web 启动器自动化安装脚本。
    该脚本会检查 Git 环境，并尝试克隆或下载启动器核心文件。
    然后，它会安装 Python 依赖并启动 Web 启动器。

.DESCRIPTION
    此脚本旨在简化 AI Builder Mod Web 启动器核心的部署过程。
    它支持两种模式：
    1. 如果检测到 Git，则使用 Git 克隆最新的启动器代码。
    2. 如果未检测到 Git，则提示用户手动下载代码包。

.PARAMETER TargetDirectory
    指定启动器安装的目录。默认为用户文档目录下的 'AIBuilderLauncher'。

.NOTES
    需要 PowerShell 5.1 或更高版本。
    需要管理员权限来安装 Python 依赖（如果需要）。
#>
param(
    [string]$TargetDirectory = "$([Environment]::GetFolderPath('MyDocuments'))\AIBuilderLauncher"
)

# --- 配置 ---
$RepositoryUrl = "https://github.com/YourGitHubUser/AIBuilderLauncher.git" # 假设的 GitHub 仓库地址
$ZipDownloadUrl = "https://github.com/YourGitHubUser/AIBuilderLauncher/archive/refs/heads/main.zip" # 假设的 ZIP 下载地址
$ModFileName = "minecraft-ai-builder-1.0.0.jar"
$ModSourcePath = "$PSScriptRoot\$ModFileName" # 假设模组文件与脚本在同一目录

# --- 辅助函数 ---

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$Timestamp] [$Level] $Message"
}

function Check-Git {
    Write-Log "正在检查 Git 是否安装..."
    try {
        # 尝试运行 git --version，如果成功则返回 $true
        git --version | Out-Null
        Write-Log "Git 已安装。" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Git 未安装。" -Level "WARNING"
        return $false
    }
}

function Install-PythonDependencies {
    Write-Log "正在安装 Python 依赖 (Flask, requests)..."
    try {
        # 确保 pip 已安装
        pip --version | Out-Null
        
        # 使用 pip 安装依赖
        $InstallResult = pip install Flask requests 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Log "pip 安装依赖失败。请确保 Python 和 pip 已正确配置。" -Level "ERROR"
            Write-Log $InstallResult
            return $false
        }
        Write-Log "Python 依赖安装成功。" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "无法执行 pip 命令。请确保 Python 和 pip 已添加到系统 PATH。" -Level "ERROR"
        return $false
    }
}

# --- 主安装逻辑 ---

Write-Log "--- AI Builder Mod Web 启动器安装程序 ---"
Write-Log "目标安装目录: $TargetDirectory"

# 1. 创建目标目录
if (-not (Test-Path $TargetDirectory)) {
    Write-Log "创建目标目录: $TargetDirectory"
    New-Item -Path $TargetDirectory -ItemType Directory | Out-Null
}

# 2. 获取启动器核心文件
$GitInstalled = Check-Git

if ($GitInstalled) {
    # 使用 Git 克隆
    Write-Log "使用 Git 克隆仓库: $RepositoryUrl"
    try {
        # 切换到目标目录的父目录进行克隆
        Set-Location (Split-Path $TargetDirectory -Parent)
        git clone $RepositoryUrl (Split-Path $TargetDirectory -Leaf)
        Write-Log "仓库克隆成功。" -Level "SUCCESS"
    } catch {
        Write-Log "Git 克隆失败。请检查网络连接或权限。" -Level "ERROR"
        exit 1
    }
} else {
    # 提示用户手动下载
    Write-Log "未检测到 Git。请手动下载启动器核心文件。" -Level "WARNING"
    Write-Host ""
    Write-Host "=================================================================="
    Write-Host "请访问以下链接下载启动器核心 ZIP 包："
    Write-Host "$ZipDownloadUrl"
    Write-Host ""
    Write-Host "下载后，请将 ZIP 包中的所有文件解压到以下目录："
    Write-Host "$TargetDirectory"
    Write-Host "=================================================================="
    Write-Host ""
    
    # 等待用户确认
    $Confirm = Read-Host "请确认您已将文件解压到目标目录 (输入 Y 继续)"
    if ($Confirm -ne "Y") {
        Write-Log "用户取消安装。" -Level "ERROR"
        exit 1
    }
}

# 3. 复制模组文件
Write-Log "正在复制 AI Builder Mod 文件..."
if (Test-Path $ModSourcePath) {
    try {
        Copy-Item -Path $ModSourcePath -Destination "$TargetDirectory\$ModFileName" -Force
        Write-Log "模组文件复制成功。" -Level "SUCCESS"
    } catch {
        Write-Log "复制模组文件失败。请确保脚本有权限访问源文件和目标目录。" -Level "ERROR"
        exit 1
    }
} else {
    Write-Log "警告: 模组文件 ($ModFileName) 未找到。请确保它与 install.ps1 在同一目录。" -Level "WARNING"
}

# 4. 安装 Python 依赖
Set-Location $TargetDirectory
if (-not (Install-PythonDependencies)) {
    Write-Log "安装依赖失败，无法启动启动器。" -Level "ERROR"
    exit 1
}

# 5. 启动 Web 启动器
Write-Log "正在启动 Web 启动器..."
try {
    # 在后台启动 Flask 应用
    Start-Process python -ArgumentList "app.py" -NoNewWindow
    
    # 尝试自动打开浏览器
    Start-Process "http://127.0.0.1:5000"
    
    Write-Log "Web 启动器已启动。请在浏览器中查看 (http://127.0.0.1:5000)。" -Level "SUCCESS"
} catch {
    Write-Log "启动 Web 启动器失败。请手动运行 'python app.py'。" -Level "ERROR"
}

Write-Log "--- 安装和启动过程完成 ---"

