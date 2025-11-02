# 首次安装脚本
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "AI 学术写作助手 - 环境配置" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 检查 Python
Write-Host "[1/4] 检查 Python..." -ForegroundColor Yellow
try {
    $pyVersion = python --version
    Write-Host "✓ $pyVersion" -ForegroundColor Green
} catch {
    Write-Host "× Python 未安装" -ForegroundColor Red
    Write-Host "请安装 Python 3.10+: https://www.python.org/downloads/`n" -ForegroundColor Yellow
    pause
    exit 1
}

# 检查 Node.js
Write-Host "[2/4] 检查 Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "× Node.js 未安装" -ForegroundColor Red
    Write-Host "请安装 Node.js 16+: https://nodejs.org/`n" -ForegroundColor Yellow
    pause
    exit 1
}

# 安装后端依赖
Write-Host "`n[3/4] 配置后端环境..." -ForegroundColor Yellow
cd backend

if (-not (Test-Path "venv")) {
    Write-Host "创建虚拟环境..." -ForegroundColor Cyan
    python -m venv venv
}

Write-Host "安装 Python 依赖..." -ForegroundColor Cyan
.\venv\Scripts\pip.exe install -r requirements.txt

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ 后端环境配置完成" -ForegroundColor Green
} else {
    Write-Host "× 后端依赖安装失败" -ForegroundColor Red
    pause
    exit 1
}

cd ..

# 安装前端依赖
Write-Host "`n[4/4] 配置前端环境..." -ForegroundColor Yellow
cd frontend

Write-Host "安装 npm 依赖 (可能需要几分钟)..." -ForegroundColor Cyan
npm install

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ 前端环境配置完成" -ForegroundColor Green
} else {
    Write-Host "× 前端依赖安装失败" -ForegroundColor Red
    pause
    exit 1
}

cd ..

# 配置 .env 文件
Write-Host "`n[5/5] 配置环境变量..." -ForegroundColor Yellow
if (-not (Test-Path "backend\.env")) {
    Write-Host "生成 .env 配置文件..." -ForegroundColor Cyan
    
    # 生成强随机密钥
    $secretKey = python -c "import secrets; print(secrets.token_urlsafe(32))"
    
    $envContent = @"
# OpenAI API 配置 (必填)
OPENAI_API_KEY=your-api-key-here
OPENAI_BASE_URL=https://api.openai.com/v1

# 润色模型配置
POLISH_MODEL=gpt-4
POLISH_API_KEY=
POLISH_BASE_URL=

# 增强模型配置
ENHANCE_MODEL=gpt-4
ENHANCE_API_KEY=
ENHANCE_BASE_URL=

# 压缩模型配置
COMPRESSION_MODEL=gpt-3.5-turbo
COMPRESSION_API_KEY=
COMPRESSION_BASE_URL=

# 安全配置 (已自动生成强密钥)
SECRET_KEY=$secretKey
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# 管理员配置 (请务必修改密码!)
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123

# 系统配置
MAX_CONCURRENT_USERS=5
HISTORY_COMPRESSION_THRESHOLD=5000
DEFAULT_USAGE_LIMIT=1
SEGMENT_SKIP_THRESHOLD=15
"@
    
    Set-Content -Path "backend\.env" -Value $envContent -Encoding UTF8
    Write-Host "✓ 已创建 backend\.env 文件并生成强密钥" -ForegroundColor Green
    Write-Host "`n⚠️  重要提示:" -ForegroundColor Yellow
    Write-Host "  1. 请编辑 backend\.env 文件" -ForegroundColor Yellow
    Write-Host "  2. 填入您的 OPENAI_API_KEY" -ForegroundColor Yellow
    Write-Host "  3. 修改 ADMIN_PASSWORD (当前为默认值 admin123)`n" -ForegroundColor Yellow
} else {
    Write-Host "✓ 配置文件已存在" -ForegroundColor Green
    
    # 检查是否使用默认密钥
    $envContent = Get-Content "backend\.env" -Raw
    if ($envContent -match "SECRET_KEY=your-secret-key-change-this-in-production") {
        Write-Host "`n⚠️  警告: 检测到默认 SECRET_KEY!" -ForegroundColor Red
        Write-Host "生成新的强密钥..." -ForegroundColor Yellow
        $newSecretKey = python -c "import secrets; print(secrets.token_urlsafe(32))"
        $envContent = $envContent -replace "SECRET_KEY=your-secret-key-change-this-in-production", "SECRET_KEY=$newSecretKey"
        Set-Content -Path "backend\.env" -Value $envContent -Encoding UTF8
        Write-Host "✓ 已更新 SECRET_KEY 为强随机密钥" -ForegroundColor Green
    }
}

# 完成
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "✓ 环境配置完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`n下一步操作:" -ForegroundColor Cyan
Write-Host "  1. 编辑配置: notepad backend\.env" -ForegroundColor White
Write-Host "  2. 启动系统: .\start-all.ps1`n" -ForegroundColor White
pause
