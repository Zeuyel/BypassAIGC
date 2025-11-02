# 启动前端服务
Write-Host "`n启动前端服务..." -ForegroundColor Green

cd frontend

# 检查依赖
if (-not (Test-Path "node_modules")) {
    Write-Host "× 未找到 node_modules!" -ForegroundColor Red
    Write-Host "请先运行: npm install`n" -ForegroundColor Yellow
    pause
    exit 1
}

# 启动前端
Write-Host "服务地址: http://localhost:3000`n" -ForegroundColor Cyan
npm run dev
