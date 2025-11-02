# 一键启动脚本
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "AI 学术写作助手 - 启动中..." -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# 启动后端
Write-Host "[1/2] 启动后端服务..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend; .\venv\Scripts\python3.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"

# 等待后端启动
Start-Sleep -Seconds 3

# 启动前端
Write-Host "[2/2] 启动前端服务..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd frontend; npm run dev"

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "✓ 系统启动完成!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "前端: http://localhost:3000" -ForegroundColor Yellow
Write-Host "后端: http://localhost:8000" -ForegroundColor Yellow
Write-Host "管理: http://localhost:3000/admin" -ForegroundColor Yellow
Write-Host "文档: http://localhost:8000/docs" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Green
