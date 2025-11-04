import os
import sys
import json
import requests
import subprocess
import shutil
import threading
from urllib.parse import urlparse
from flask import Flask, render_template, request, jsonify
from flask_cors import CORS

# --- 配置 ---
LAUNCHER_DIR = os.path.expanduser("~/.minecraft-ai-launcher")
MOD_FILE_PATH = os.path.expanduser("~/minecraft-ai-builder-1.0.0.jar")
FABRIC_INSTALLER_URL = "https://maven.fabricmc.net/net/fabricmc/fabric-installer/0.11.2/fabric-installer-0.11.2.jar"
FABRIC_META_URL = "https://meta.fabricmc.net/v2"
FABRIC_API_MODRINTH_ID = "fabric-api"

# --- Flask 应用初始化 ---
app = Flask(__name__)
CORS(app)

# 用于存储安装进度的全局状态
installation_status = {}

# --- 工具函数 ---

def download_file(url, path):
    """下载文件到指定路径"""
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        with open(path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        return True
    except requests.exceptions.RequestException as e:
        print(f"下载失败: {e}")
        return False

def get_latest_fabric_version(mc_version):
    """获取指定MC版本的最新Fabric Loader版本"""
    try:
        url = f"{FABRIC_META_URL}/versions/loader/{mc_version}"
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        if data:
            return data[0]['loader']['version']
        return None
    except requests.exceptions.RequestException as e:
        print(f"无法获取 Fabric Loader 版本: {e}")
        return None

def get_fabric_api_download_url(mc_version):
    """从Modrinth获取Fabric API的下载链接"""
    try:
        url = f"https://api.modrinth.com/v2/project/{FABRIC_API_MODRINTH_ID}/version"
        response = requests.get(url)
        response.raise_for_status()
        versions = response.json()

        for version in versions:
            if mc_version in version['game_versions'] and 'fabric' in version['loaders']:
                for file in version['files']:
                    if file['primary']:
                        return file['url']
        return None
    except requests.exceptions.RequestException as e:
        print(f"无法获取 Fabric API 下载链接: {e}")
        return None

def setup_environment_async(mc_version):
    """异步设置环境"""
    installation_status[mc_version] = {
        'status': 'installing',
        'progress': 0,
        'message': '正在检查 Fabric Loader 版本...'
    }
    
    try:
        # 1. 检查 Fabric Loader 版本
        fabric_loader_version = get_latest_fabric_version(mc_version)
        if not fabric_loader_version:
            installation_status[mc_version] = {
                'status': 'error',
                'message': f'找不到 Minecraft {mc_version} 对应的 Fabric Loader 版本。'
            }
            return

        # 2. 创建工作目录
        mc_install_dir = os.path.join(LAUNCHER_DIR, mc_version)
        mods_dir = os.path.join(mc_install_dir, "mods")
        os.makedirs(mods_dir, exist_ok=True)
        
        installation_status[mc_version]['progress'] = 20
        installation_status[mc_version]['message'] = '工作目录已创建。正在下载 Fabric Installer...'

        # 3. 下载 Fabric Installer
        installer_path = os.path.join(LAUNCHER_DIR, "fabric-installer.jar")
        if not os.path.exists(installer_path):
            if not download_file(FABRIC_INSTALLER_URL, installer_path):
                installation_status[mc_version] = {
                    'status': 'error',
                    'message': '下载 Fabric Installer 失败。'
                }
                return

        installation_status[mc_version]['progress'] = 40
        installation_status[mc_version]['message'] = '正在运行 Fabric Installer...'

        # 4. 运行 Fabric Installer
        try:
            subprocess.run([
                "java", 
                "-jar", 
                installer_path, 
                "client", 
                "-mcversion", mc_version, 
                "-loader", fabric_loader_version, 
                "-dir", mc_install_dir,
                "-noprofile"
            ], check=True, capture_output=True, text=True, timeout=300)
        except subprocess.CalledProcessError as e:
            installation_status[mc_version] = {
                'status': 'error',
                'message': f'Fabric Installer 运行失败。请检查 Java 环境。'
            }
            return

        installation_status[mc_version]['progress'] = 60
        installation_status[mc_version]['message'] = '正在下载 Fabric API...'

        # 5. 下载 Fabric API
        fabric_api_url = get_fabric_api_download_url(mc_version)
        if fabric_api_url:
            fabric_api_path = os.path.join(mods_dir, os.path.basename(urlparse(fabric_api_url).path))
            if not download_file(fabric_api_url, fabric_api_path):
                installation_status[mc_version] = {
                    'status': 'error',
                    'message': '下载 Fabric API 失败。'
                }
                return
        else:
            installation_status[mc_version]['message'] = '警告: 找不到对应的 Fabric API 版本。请手动下载。'

        installation_status[mc_version] = {
            'status': 'success',
            'progress': 100,
            'message': f'Minecraft {mc_version} Fabric 环境设置完成',
            'install_dir': mc_install_dir
        }
    except Exception as e:
        installation_status[mc_version] = {
            'status': 'error',
            'message': f'设置环境时出错: {str(e)}'
        }

# --- API 路由 ---

@app.route('/')
def index():
    """主页面"""
    return render_template('index.html')

@app.route('/api/versions', methods=['GET'])
def get_versions():
    """获取可用的 Minecraft 版本"""
    try:
        url = f"{FABRIC_META_URL}/versions/game"
        response = requests.get(url)
        response.raise_for_status()
        versions = response.json()
        
        version_list = []
        for version in versions[:20]:  # 只返回前 20 个版本
            version_list.append({
                'id': version['version'],
                'name': version['version'],
                'stable': version['stable']
            })
        
        return jsonify({
            'status': 'success',
            'versions': version_list
        })
    except requests.exceptions.RequestException as e:
        return jsonify({
            'status': 'error',
            'message': f'无法获取版本列表: {str(e)}'
        }), 500

@app.route('/api/setup', methods=['POST'])
def setup():
    """设置 Minecraft Fabric 环境"""
    data = request.get_json()
    mc_version = data.get('mc_version')
    
    if not mc_version:
        return jsonify({
            'status': 'error',
            'message': '缺少 mc_version 参数'
        }), 400
    
    # 异步运行安装过程
    thread = threading.Thread(target=setup_environment_async, args=(mc_version,))
    thread.daemon = True
    thread.start()
    
    return jsonify({
        'status': 'success',
        'message': '正在设置环境，请稍候...',
        'mc_version': mc_version
    })

@app.route('/api/install-mod', methods=['POST'])
def install_mod():
    """安装 AI Builder Mod"""
    data = request.get_json()
    mc_version = data.get('mc_version')
    install_ai_mod = data.get('install_ai_mod', True)
    
    if not mc_version:
        return jsonify({
            'status': 'error',
            'message': '缺少 mc_version 参数'
        }), 400
    
    mods_dir = os.path.join(LAUNCHER_DIR, mc_version, "mods")
    if not os.path.isdir(mods_dir):
        return jsonify({
            'status': 'error',
            'message': f'找不到 {mc_version} 的 mods 目录。请先运行 setup。'
        }), 400
    
    if not install_ai_mod:
        return jsonify({
            'status': 'success',
            'message': '跳过 AI Builder Mod 安装'
        })
    
    if not os.path.exists(MOD_FILE_PATH):
        return jsonify({
            'status': 'error',
            'message': f'找不到模组文件: {MOD_FILE_PATH}'
        }), 400
    
    try:
        shutil.copy(MOD_FILE_PATH, mods_dir)
        return jsonify({
            'status': 'success',
            'message': 'AI Builder Mod 安装成功',
            'mod_path': os.path.join(mods_dir, os.path.basename(MOD_FILE_PATH))
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'安装模组失败: {str(e)}'
        }), 500

@app.route('/api/launch', methods=['POST'])
def launch():
    """启动游戏"""
    data = request.get_json()
    mc_version = data.get('mc_version')
    
    if not mc_version:
        return jsonify({
            'status': 'error',
            'message': '缺少 mc_version 参数'
        }), 400
    
    mc_install_dir = os.path.join(LAUNCHER_DIR, mc_version)
    if not os.path.isdir(mc_install_dir):
        return jsonify({
            'status': 'error',
            'message': f'找不到 {mc_version} 的安装目录。'
        }), 400
    
    fabric_loader_version = get_latest_fabric_version(mc_version)
    
    launch_instructions = f"""
由于命令行环境的限制，我们无法直接启动游戏。请按以下步骤操作：

1. 打开官方 Minecraft 启动器。
2. 进入"安装"选项卡。
3. 点击"新建安装"。
4. 在"版本"下拉菜单中，选择: fabric-loader-{fabric_loader_version}-{mc_version}
5. 在"游戏目录"选项中，设置为: {mc_install_dir}
6. 点击"创建"，然后启动游戏。
"""
    
    return jsonify({
        'status': 'success',
        'message': '启动说明已生成',
        'launch_instructions': launch_instructions
    })

@app.route('/api/status/<mc_version>', methods=['GET'])
def get_status(mc_version):
    """获取安装状态"""
    mc_install_dir = os.path.join(LAUNCHER_DIR, mc_version)
    mods_dir = os.path.join(mc_install_dir, "mods")
    
    # 检查安装状态
    installed = os.path.isdir(mc_install_dir)
    fabric_api_installed = False
    ai_mod_installed = False
    
    if installed and os.path.isdir(mods_dir):
        for file in os.listdir(mods_dir):
            if 'fabric-api' in file.lower():
                fabric_api_installed = True
            if 'ai-builder' in file.lower() or 'ai_builder' in file.lower():
                ai_mod_installed = True
    
    # 检查是否正在安装
    if mc_version in installation_status:
        return jsonify({
            'status': 'success',
            'mc_version': mc_version,
            'installation_status': installation_status[mc_version]
        })
    
    return jsonify({
        'status': 'success',
        'mc_version': mc_version,
        'installed': installed,
        'fabric_installed': installed,
        'fabric_api_installed': fabric_api_installed,
        'ai_mod_installed': ai_mod_installed
    })

if __name__ == '__main__':
    # 确保启动器目录存在
    os.makedirs(LAUNCHER_DIR, exist_ok=True)
    
    # 启动 Flask 应用
    app.run(debug=True, host='127.0.0.1', port=5000)

