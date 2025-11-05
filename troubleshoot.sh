#!/bin/bash
# 故障排查脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}BypassAIGC 故障排查工具${NC}"
echo -e "${CYAN}========================================${NC}\n"

# 收集系统信息
echo -e "${YELLOW}收集系统信息...${NC}\n"

echo "系统信息:"
uname -a
echo ""

echo "Python 版本:"
python3 --version 2>&1 || echo "未安装"
echo ""

echo "Node.js 版本:"
node --version 2>&1 || echo "未安装"
npm --version 2>&1 || echo "未安装"
echo ""

echo "磁盘空间:"
df -h "$SCRIPT_DIR" | tail -n 1
echo ""

echo "内存使用:"
free -h 2>/dev/null || echo "N/A"
echo ""

# 检查进程
echo -e "\n${YELLOW}检查运行中的进程...${NC}\n"

echo "后端进程 (端口 8000):"
if lsof -Pi :8000 -sTCP:LISTEN 2>/dev/null; then
    echo -e "${GREEN}后端正在运行${NC}"
else
    echo -e "${YELLOW}后端未运行${NC}"
fi
echo ""

echo "前端进程 (端口 3000):"
if lsof -Pi :3000 -sTCP:LISTEN 2>/dev/null; then
    echo -e "${GREEN}前端正在运行${NC}"
else
    echo -e "${YELLOW}前端未运行${NC}"
fi
echo ""

# 检查日志
echo -e "\n${YELLOW}检查日志文件...${NC}\n"

if [ -f "$SCRIPT_DIR/backend/backend.log" ]; then
    echo "最近的后端日志 (最后 10 行):"
    tail -n 10 "$SCRIPT_DIR/backend/backend.log"
    echo ""
else
    echo "后端日志不存在"
fi

if [ -f "$SCRIPT_DIR/frontend/frontend.log" ]; then
    echo "最近的前端日志 (最后 10 行):"
    tail -n 10 "$SCRIPT_DIR/frontend/frontend.log"
    echo ""
else
    echo "前端日志不存在"
fi

# 检查配置
echo -e "\n${YELLOW}检查配置文件...${NC}\n"

if [ -f "$SCRIPT_DIR/backend/.env" ]; then
    echo ".env 文件内容 (敏感信息已隐藏):"
    grep -v "API_KEY\|PASSWORD\|SECRET" "$SCRIPT_DIR/backend/.env" || echo "无法读取"
    echo ""
else
    echo -e "${RED}.env 文件不存在${NC}"
    echo ""
fi

# 检查数据库
echo -e "\n${YELLOW}检查数据库...${NC}\n"

if [ -f "$SCRIPT_DIR/backend/ai_polish.db" ]; then
    DB_SIZE=$(du -h "$SCRIPT_DIR/backend/ai_polish.db" | cut -f1)
    echo -e "数据库文件: ${GREEN}存在${NC} (大小: $DB_SIZE)"
    
    # 尝试检查数据库结构
    cd "$SCRIPT_DIR/backend"
    if [ -d "venv" ]; then
        source venv/bin/activate
        python -c "
from sqlalchemy import create_engine, inspect
try:
    engine = create_engine('sqlite:///./ai_polish.db')
    inspector = inspect(engine)
    tables = inspector.get_table_names()
    print(f'数据库表数量: {len(tables)}')
    print(f'表列表: {', '.join(tables)}')
except Exception as e:
    print(f'错误: {str(e)}')
" 2>&1
        deactivate
    fi
    cd "$SCRIPT_DIR"
else
    echo -e "${YELLOW}数据库文件不存在（首次运行时会自动创建）${NC}"
fi
echo ""

# 网络测试
echo -e "\n${YELLOW}网络连接测试...${NC}\n"

echo "测试本地后端连接:"
if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 后端健康检查成功${NC}"
else
    echo -e "${YELLOW}✗ 无法连接到后端${NC}"
fi
echo ""

echo "测试本地前端连接:"
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 前端连接成功${NC}"
else
    echo -e "${YELLOW}✗ 无法连接到前端${NC}"
fi
echo ""

# 依赖检查
echo -e "\n${YELLOW}检查关键依赖...${NC}\n"

if [ -d "$SCRIPT_DIR/backend/venv" ]; then
    cd "$SCRIPT_DIR/backend"
    source venv/bin/activate
    
    echo "Python 包:"
    python -c "
import sys
packages = ['fastapi', 'uvicorn', 'sqlalchemy', 'openai', 'pydantic']
for pkg in packages:
    try:
        __import__(pkg)
        print(f'  ✓ {pkg}')
    except ImportError:
        print(f'  ✗ {pkg}')
"
    deactivate
    cd "$SCRIPT_DIR"
else
    echo -e "${RED}虚拟环境不存在${NC}"
fi
echo ""

# 建议
echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}故障排查建议${NC}"
echo -e "${CYAN}========================================${NC}\n"

echo "常见问题解决方案:"
echo ""
echo "1. 如果端口被占用:"
echo "   ${YELLOW}./stop-all.sh${NC}"
echo ""
echo "2. 如果配置有误:"
echo "   ${YELLOW}nano backend/.env${NC}"
echo "   然后重启服务"
echo ""
echo "3. 如果数据库损坏:"
echo "   ${YELLOW}rm backend/ai_polish.db${NC}"
echo "   ${YELLOW}./verify-database.sh${NC}"
echo ""
echo "4. 如果依赖缺失:"
echo "   ${YELLOW}./setup.sh${NC}"
echo ""
echo "5. 查看完整验证:"
echo "   ${YELLOW}./verify-installation.sh${NC}"
echo ""
echo "6. 查看后端日志:"
echo "   ${YELLOW}tail -f backend/backend.log${NC}"
echo ""
echo "7. 查看前端日志:"
echo "   ${YELLOW}tail -f frontend/frontend.log${NC}"
echo ""

# 生成诊断报告
REPORT_FILE="/tmp/bypassaigc-diagnostic-$(date +%Y%m%d-%H%M%S).txt"
{
    echo "BypassAIGC 诊断报告"
    echo "生成时间: $(date)"
    echo ""
    echo "系统信息:"
    uname -a
    echo ""
    echo "Python: $(python3 --version 2>&1)"
    echo "Node.js: $(node --version 2>&1)"
    echo ""
    echo "进程状态:"
    lsof -Pi :8000,3000 -sTCP:LISTEN 2>&1 || echo "无进程监听"
    echo ""
    if [ -f "$SCRIPT_DIR/backend/backend.log" ]; then
        echo "后端日志 (最后 50 行):"
        tail -n 50 "$SCRIPT_DIR/backend/backend.log"
    fi
} > "$REPORT_FILE"

echo -e "${GREEN}诊断报告已保存到: $REPORT_FILE${NC}\n"
