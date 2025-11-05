# 完整的安装验证脚本 - Windows 版本

$Errors = 0
$Warnings = 0

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "BypassAIGC 安装验证" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 1. 检查 Python
Write-Host "[1/8] 检查 Python..." -ForegroundColor Yellow
try {
    $pyVersion = python --version 2>&1
    if ($pyVersion -match "Python (\d+)\.(\d+)") {
        $major = [int]$matches[1]
        $minor = [int]$matches[2]
        if ($major -ge 3 -and $minor -ge 10) {
            Write-Host "✓ $pyVersion" -ForegroundColor Green
        } else {
            Write-Host "× Python 版本过低（需要 3.10+）" -ForegroundColor Red
            $Errors++
        }
    }
} catch {
    Write-Host "× Python 未安装" -ForegroundColor Red
    $Errors++
}

# 2. 检查 Node.js
Write-Host "`n[2/8] 检查 Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version 2>&1
    if ($nodeVersion -match "v(\d+)") {
        $major = [int]$matches[1]
        if ($major -ge 16) {
            Write-Host "✓ Node.js $nodeVersion" -ForegroundColor Green
        } else {
            Write-Host "× Node.js 版本过低（需要 16+）" -ForegroundColor Red
            $Errors++
        }
    }
} catch {
    Write-Host "× Node.js 未安装" -ForegroundColor Red
    $Errors++
}

# 3. 检查后端虚拟环境
Write-Host "`n[3/8] 检查后端环境..." -ForegroundColor Yellow
if (Test-Path "backend\venv") {
    Write-Host "✓ 虚拟环境存在" -ForegroundColor Green
    
    # 检查关键依赖
    $fastapi = & backend\venv\Scripts\python.exe -c "import fastapi" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ FastAPI 已安装" -ForegroundColor Green
    } else {
        Write-Host "× FastAPI 未安装" -ForegroundColor Red
        $Errors++
    }
    
    $sqlalchemy = & backend\venv\Scripts\python.exe -c "import sqlalchemy" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ SQLAlchemy 已安装" -ForegroundColor Green
    } else {
        Write-Host "× SQLAlchemy 未安装" -ForegroundColor Red
        $Errors++
    }
} else {
    Write-Host "× 虚拟环境不存在" -ForegroundColor Red
    $Errors++
}

# 4. 检查前端依赖
Write-Host "`n[4/8] 检查前端环境..." -ForegroundColor Yellow
if (Test-Path "frontend\node_modules") {
    Write-Host "✓ node_modules 存在" -ForegroundColor Green
    
    if (Test-Path "frontend\node_modules\react") {
        Write-Host "✓ React 已安装" -ForegroundColor Green
    } else {
        Write-Host "⚠ React 未找到" -ForegroundColor Yellow
        $Warnings++
    }
} else {
    Write-Host "× node_modules 不存在" -ForegroundColor Red
    $Errors++
}

# 5. 检查配置文件
Write-Host "`n[5/8] 检查配置文件..." -ForegroundColor Yellow
if (Test-Path "backend\.env") {
    Write-Host "✓ .env 文件存在" -ForegroundColor Green
    
    $envContent = Get-Content "backend\.env" -Raw
    
    if ($envContent -match "OPENAI_API_KEY=your-api-key-here") {
        Write-Host "⚠ OPENAI_API_KEY 使用默认值" -ForegroundColor Yellow
        $Warnings++
    } else {
        Write-Host "✓ OPENAI_API_KEY 已配置" -ForegroundColor Green
    }
    
    if ($envContent -match "ADMIN_PASSWORD=admin123") {
        Write-Host "⚠ 管理员密码使用默认值（不安全）" -ForegroundColor Yellow
        $Warnings++
    } else {
        Write-Host "✓ 管理员密码已修改" -ForegroundColor Green
    }
    
    if ($envContent -match "SECRET_KEY=your-secret-key") {
        Write-Host "× SECRET_KEY 使用默认值（不安全）" -ForegroundColor Red
        $Errors++
    } else {
        Write-Host "✓ SECRET_KEY 已配置" -ForegroundColor Green
    }
} else {
    Write-Host "× .env 文件不存在" -ForegroundColor Red
    $Errors++
}

# 6. 检查数据库
Write-Host "`n[6/8] 检查数据库..." -ForegroundColor Yellow
cd backend
& .\venv\Scripts\python.exe init_db.py > $null 2>&1
$dbCheck = $LASTEXITCODE
cd ..

if ($dbCheck -eq 0) {
    Write-Host "✓ 数据库初始化成功" -ForegroundColor Green
} else {
    Write-Host "× 数据库初始化失败" -ForegroundColor Red
    $Errors++
}

# 7. 检查端口占用
Write-Host "`n[7/8] 检查端口占用..." -ForegroundColor Yellow
try {
    $port8000 = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
    if ($port8000) {
        Write-Host "⚠ 端口 8000 已被占用" -ForegroundColor Yellow
        $Warnings++
    } else {
        Write-Host "✓ 端口 8000 可用" -ForegroundColor Green
    }
} catch {
    Write-Host "✓ 端口 8000 可用" -ForegroundColor Green
}

try {
    $port3000 = Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue
    if ($port3000) {
        Write-Host "⚠ 端口 3000 已被占用" -ForegroundColor Yellow
        $Warnings++
    } else {
        Write-Host "✓ 端口 3000 可用" -ForegroundColor Green
    }
} catch {
    Write-Host "✓ 端口 3000 可用" -ForegroundColor Green
}

# 8. 检查脚本文件
Write-Host "`n[8/8] 检查脚本文件..." -ForegroundColor Yellow
$scripts = @("setup.ps1", "start-backend.ps1", "start-frontend.ps1", "start-all.ps1")
foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "✓ $script 存在" -ForegroundColor Green
    } else {
        Write-Host "× $script 不存在" -ForegroundColor Red
        $Errors++
    }
}

# 总结
Write-Host "`n========================================" -ForegroundColor Cyan
if ($Errors -eq 0 -and $Warnings -eq 0) {
    Write-Host "✓ 所有检查通过!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "`n可以启动应用:" -ForegroundColor Cyan
    Write-Host "  .\start-all.ps1`n" -ForegroundColor Yellow
} elseif ($Errors -eq 0) {
    Write-Host "⚠ 检查完成，有 $Warnings 个警告" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow
    Write-Host "`n可以启动应用，但建议修复警告:" -ForegroundColor Cyan
    Write-Host "  .\start-all.ps1`n" -ForegroundColor Yellow
} else {
    Write-Host "✗ 检查失败，发现 $Errors 个错误和 $Warnings 个警告" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "`n请先解决错误:" -ForegroundColor Cyan
    Write-Host "  1. 运行安装脚本: .\setup.ps1" -ForegroundColor Yellow
    Write-Host "  2. 配置环境变量: notepad backend\.env" -ForegroundColor Yellow
    Write-Host "  3. 再次验证: .\verify-installation.ps1`n" -ForegroundColor Yellow
    exit 1
}

pause
