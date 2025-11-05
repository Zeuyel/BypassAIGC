#!/bin/bash
# 完整的安装验证脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ERRORS=0
WARNINGS=0

echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}BypassAIGC 安装验证${NC}"
echo -e "${CYAN}========================================${NC}\n"

# 1. 检查 Python
echo -e "${YELLOW}[1/8] 检查 Python...${NC}"
if command -v python3 &> /dev/null; then
    PY_VERSION=$(python3 --version)
    echo -e "${GREEN}✓ $PY_VERSION${NC}"
    
    PY_MAJOR=$(python3 -c 'import sys; print(sys.version_info.major)')
    PY_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')
    if [ "$PY_MAJOR" -lt 3 ] || ([ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 10 ]); then
        echo -e "${RED}× Python 版本过低（需要 3.10+）${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${RED}× Python3 未安装${NC}"
    ERRORS=$((ERRORS + 1))
fi

# 2. 检查 Node.js
echo -e "\n${YELLOW}[2/8] 检查 Node.js...${NC}"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓ Node.js $NODE_VERSION${NC}"
    
    NODE_MAJOR=$(node -p 'process.version.split(".")[0].slice(1)')
    if [ "$NODE_MAJOR" -lt 16 ]; then
        echo -e "${RED}× Node.js 版本过低（需要 16+）${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${RED}× Node.js 未安装${NC}"
    ERRORS=$((ERRORS + 1))
fi

# 3. 检查后端虚拟环境
echo -e "\n${YELLOW}[3/8] 检查后端环境...${NC}"
if [ -d "$SCRIPT_DIR/backend/venv" ]; then
    echo -e "${GREEN}✓ 虚拟环境存在${NC}"
    
    # 检查关键依赖
    source "$SCRIPT_DIR/backend/venv/bin/activate"
    if python -c "import fastapi" 2>/dev/null; then
        echo -e "${GREEN}✓ FastAPI 已安装${NC}"
    else
        echo -e "${RED}× FastAPI 未安装${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    
    if python -c "import sqlalchemy" 2>/dev/null; then
        echo -e "${GREEN}✓ SQLAlchemy 已安装${NC}"
    else
        echo -e "${RED}× SQLAlchemy 未安装${NC}"
        ERRORS=$((ERRORS + 1))
    fi
    deactivate
else
    echo -e "${RED}× 虚拟环境不存在${NC}"
    ERRORS=$((ERRORS + 1))
fi

# 4. 检查前端依赖
echo -e "\n${YELLOW}[4/8] 检查前端环境...${NC}"
if [ -d "$SCRIPT_DIR/frontend/node_modules" ]; then
    echo -e "${GREEN}✓ node_modules 存在${NC}"
    
    # 检查关键包
    if [ -d "$SCRIPT_DIR/frontend/node_modules/react" ]; then
        echo -e "${GREEN}✓ React 已安装${NC}"
    else
        echo -e "${YELLOW}⚠ React 未找到${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    echo -e "${RED}× node_modules 不存在${NC}"
    ERRORS=$((ERRORS + 1))
fi

# 5. 检查配置文件
echo -e "\n${YELLOW}[5/8] 检查配置文件...${NC}"
if [ -f "$SCRIPT_DIR/backend/.env" ]; then
    echo -e "${GREEN}✓ .env 文件存在${NC}"
    
    # 检查关键配置
    if grep -q "OPENAI_API_KEY=your-api-key-here" "$SCRIPT_DIR/backend/.env"; then
        echo -e "${YELLOW}⚠ OPENAI_API_KEY 使用默认值${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✓ OPENAI_API_KEY 已配置${NC}"
    fi
    
    if grep -q "ADMIN_PASSWORD=admin123" "$SCRIPT_DIR/backend/.env"; then
        echo -e "${YELLOW}⚠ 管理员密码使用默认值（不安全）${NC}"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${GREEN}✓ 管理员密码已修改${NC}"
    fi
    
    if grep -q "SECRET_KEY=your-secret-key" "$SCRIPT_DIR/backend/.env"; then
        echo -e "${RED}× SECRET_KEY 使用默认值（不安全）${NC}"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✓ SECRET_KEY 已配置${NC}"
    fi
else
    echo -e "${RED}× .env 文件不存在${NC}"
    ERRORS=$((ERRORS + 1))
fi

# 6. 检查数据库
echo -e "\n${YELLOW}[6/8] 检查数据库...${NC}"
cd "$SCRIPT_DIR/backend"
source venv/bin/activate
python init_db.py > /tmp/db_check.log 2>&1
DB_CHECK=$?
deactivate
cd "$SCRIPT_DIR"

if [ $DB_CHECK -eq 0 ]; then
    echo -e "${GREEN}✓ 数据库初始化成功${NC}"
else
    echo -e "${RED}× 数据库初始化失败${NC}"
    echo -e "${YELLOW}查看详细日志: cat /tmp/db_check.log${NC}"
    ERRORS=$((ERRORS + 1))
fi

# 7. 检查端口占用
echo -e "\n${YELLOW}[7/8] 检查端口占用...${NC}"
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ 端口 8000 已被占用${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓ 端口 8000 可用${NC}"
fi

if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ 端口 3000 已被占用${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓ 端口 3000 可用${NC}"
fi

# 8. 检查脚本权限
echo -e "\n${YELLOW}[8/8] 检查脚本权限...${NC}"
SCRIPTS=("setup.sh" "start-backend.sh" "start-frontend.sh" "start-all.sh" "stop-all.sh" "verify-database.sh")
for script in "${SCRIPTS[@]}"; do
    if [ -x "$SCRIPT_DIR/$script" ]; then
        echo -e "${GREEN}✓ $script 可执行${NC}"
    else
        echo -e "${YELLOW}⚠ $script 不可执行${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
done

# 总结
echo -e "\n${CYAN}========================================${NC}"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ 所有检查通过!${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    echo -e "${CYAN}可以启动应用:${NC}"
    echo -e "  ${YELLOW}./start-all.sh${NC}\n"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ 检查完成，有 $WARNINGS 个警告${NC}"
    echo -e "${YELLOW}========================================${NC}\n"
    echo -e "${CYAN}可以启动应用，但建议修复警告:${NC}"
    echo -e "  ${YELLOW}./start-all.sh${NC}\n"
    exit 0
else
    echo -e "${RED}✗ 检查失败，发现 $ERRORS 个错误和 $WARNINGS 个警告${NC}"
    echo -e "${RED}========================================${NC}\n"
    echo -e "${CYAN}请先解决错误:${NC}"
    echo -e "  1. 运行安装脚本: ${YELLOW}./setup.sh${NC}"
    echo -e "  2. 配置环境变量: ${YELLOW}nano backend/.env${NC}"
    echo -e "  3. 再次验证: ${YELLOW}./verify-installation.sh${NC}\n"
    exit 1
fi
