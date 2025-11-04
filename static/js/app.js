// 全局变量
let currentVersion = null;
const API_BASE = '/api';

// 日志函数
function addLog(message, type = 'info') {
    const logOutput = document.getElementById('logOutput');
    const timestamp = new Date().toLocaleTimeString();
    const entry = document.createElement('div');
    entry.className = 'log-entry';
    entry.innerHTML = `<span class="log-time">[${timestamp}]</span> ${message}`;
    logOutput.appendChild(entry);
    logOutput.scrollTop = logOutput.scrollHeight;
}

// 页面加载时初始化
document.addEventListener('DOMContentLoaded', function() {
    addLog('启动器已加载');
    loadVersions();
});

// 加载版本列表
async function loadVersions() {
    try {
        addLog('正在加载版本列表...');
        const response = await fetch(`${API_BASE}/versions`);
        const data = await response.json();
        
        if (data.status === 'success') {
            const select = document.getElementById('versionSelect');
            select.innerHTML = '<option value="">请选择版本</option>';
            
            data.versions.forEach(version => {
                const option = document.createElement('option');
                option.value = version.id;
                option.textContent = `${version.name} ${version.stable ? '(稳定)' : '(快照)'}`;
                select.appendChild(option);
            });
            
            select.addEventListener('change', function() {
                currentVersion = this.value;
                if (currentVersion) {
                    addLog(`已选择版本: ${currentVersion}`);
                    updateVersionInfo();
                }
            });
            
            addLog(`成功加载 ${data.versions.length} 个版本`);
        } else {
            addLog(`错误: ${data.message}`, 'error');
        }
    } catch (error) {
        addLog(`加载版本列表失败: ${error.message}`, 'error');
    }
}

// 更新版本信息
function updateVersionInfo() {
    const infoBox = document.getElementById('versionInfo');
    if (currentVersion) {
        infoBox.innerHTML = `<strong>已选择版本:</strong> ${currentVersion}`;
        infoBox.classList.add('show');
    } else {
        infoBox.classList.remove('show');
    }
}

// 设置环境
async function setupEnvironment() {
    if (!currentVersion) {
        alert('请先选择一个 Minecraft 版本');
        return;
    }
    
    try {
        addLog(`开始设置 Minecraft ${currentVersion} 的 Fabric 环境...`);
        
        const progressContainer = document.getElementById('setupProgress');
        progressContainer.style.display = 'block';
        
        const response = await fetch(`${API_BASE}/setup`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ mc_version: currentVersion })
        });
        
        const data = await response.json();
        
        if (data.status === 'success') {
            addLog(data.message);
            
            // 定期检查安装状态
            const checkInterval = setInterval(async () => {
                try {
                    const statusResponse = await fetch(`${API_BASE}/status/${currentVersion}`);
                    const statusData = await statusResponse.json();
                    
                    if (statusData.installation_status) {
                        const status = statusData.installation_status;
                        const progressFill = document.getElementById('progressFill');
                        const setupMessage = document.getElementById('setupMessage');
                        
                        progressFill.style.width = status.progress + '%';
                        progressFill.textContent = status.progress + '%';
                        setupMessage.textContent = status.message;
                        
                        addLog(`[进度] ${status.progress}% - ${status.message}`);
                        
                        if (status.status === 'success') {
                            clearInterval(checkInterval);
                            addLog(`✓ Minecraft ${currentVersion} Fabric 环境设置完成`);
                        } else if (status.status === 'error') {
                            clearInterval(checkInterval);
                            addLog(`✗ 设置失败: ${status.message}`, 'error');
                        }
                    }
                } catch (error) {
                    console.error('检查状态失败:', error);
                }
            }, 1000);
        } else {
            addLog(`错误: ${data.message}`, 'error');
        }
    } catch (error) {
        addLog(`设置环境失败: ${error.message}`, 'error');
    }
}

// 安装模组
async function installMods() {
    if (!currentVersion) {
        alert('请先选择一个 Minecraft 版本');
        return;
    }
    
    try {
        const installAIMod = document.getElementById('installAIMod').checked;
        addLog(`开始安装模组 (AI Builder Mod: ${installAIMod ? '是' : '否'})...`);
        
        const response = await fetch(`${API_BASE}/install-mod`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                mc_version: currentVersion,
                install_ai_mod: installAIMod
            })
        });
        
        const data = await response.json();
        
        const statusDiv = document.getElementById('modInstallStatus');
        statusDiv.classList.add('show');
        
        if (data.status === 'success') {
            statusDiv.classList.add('success');
            statusDiv.classList.remove('error');
            statusDiv.innerHTML = `<strong>✓ 成功:</strong> ${data.message}`;
            addLog(`✓ ${data.message}`);
        } else {
            statusDiv.classList.add('error');
            statusDiv.classList.remove('success');
            statusDiv.innerHTML = `<strong>✗ 错误:</strong> ${data.message}`;
            addLog(`✗ ${data.message}`, 'error');
        }
    } catch (error) {
        addLog(`安装模组失败: ${error.message}`, 'error');
    }
}

// 启动游戏
async function launchGame() {
    if (!currentVersion) {
        alert('请先选择一个 Minecraft 版本');
        return;
    }
    
    try {
        addLog(`获取 Minecraft ${currentVersion} 的启动说明...`);
        
        const response = await fetch(`${API_BASE}/launch`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ mc_version: currentVersion })
        });
        
        const data = await response.json();
        
        const instructionsDiv = document.getElementById('launchInstructions');
        instructionsDiv.classList.add('show');
        
        if (data.status === 'success') {
            instructionsDiv.innerHTML = data.launch_instructions.replace(/\n/g, '<br>');
            addLog('✓ 启动说明已生成');
        } else {
            instructionsDiv.innerHTML = `<strong>错误:</strong> ${data.message}`;
            addLog(`✗ ${data.message}`, 'error');
        }
    } catch (error) {
        addLog(`获取启动说明失败: ${error.message}`, 'error');
    }
}

// 检查安装状态
async function checkStatus() {
    if (!currentVersion) {
        alert('请先选择一个 Minecraft 版本');
        return;
    }
    
    try {
        addLog(`检查 Minecraft ${currentVersion} 的安装状态...`);
        
        const response = await fetch(`${API_BASE}/status/${currentVersion}`);
        const data = await response.json();
        
        const statusDiv = document.getElementById('statusInfo');
        statusDiv.classList.add('show');
        
        if (data.status === 'success') {
            let html = '<ul>';
            
            const items = [
                { label: 'Minecraft 已安装', value: data.installed },
                { label: 'Fabric 已安装', value: data.fabric_installed },
                { label: 'Fabric API 已安装', value: data.fabric_api_installed },
                { label: 'AI Builder Mod 已安装', value: data.ai_mod_installed }
            ];
            
            items.forEach(item => {
                const badge = item.value ? 
                    '<span class="status-badge installed">✓ 已安装</span>' : 
                    '<span class="status-badge not-installed">✗ 未安装</span>';
                html += `<li><div class="status-item"><span>${item.label}</span>${badge}</div></li>`;
            });
            
            html += '</ul>';
            statusDiv.innerHTML = html;
            addLog('✓ 状态检查完成');
        } else {
            statusDiv.innerHTML = `<strong>错误:</strong> ${data.message}`;
            addLog(`✗ ${data.message}`, 'error');
        }
    } catch (error) {
        addLog(`检查状态失败: ${error.message}`, 'error');
    }
}

// 清除日志
function clearLog() {
    document.getElementById('logOutput').innerHTML = '';
    addLog('日志已清除');
}

