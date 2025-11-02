#!/bin/bash
# Ubuntu/Linux 环境安装脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}AI 学术写作助手 - 环境配置${NC}"
echo -e "${CYAN}========================================${NC}\n"

# 检查 Python3
echo -e "${YELLOW}[1/4] 检查 Python3...${NC}"
if command -v python3 &> /dev/null; then
    PY_VERSION=$(python3 --version)
    echo -e "${GREEN}✓ $PY_VERSION${NC}"
    
    # 检查版本是否 >= 3.10
    PY_MAJOR=$(python3 -c 'import sys; print(sys.version_info.major)')
    PY_MINOR=$(python3 -c 'import sys; print(sys.version_info.minor)')
    if [ "$PY_MAJOR" -lt 3 ] || ([ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 10 ]); then
        echo -e "${RED}× Python 版本过低,需要 3.10+${NC}"
        echo -e "${YELLOW}请升级 Python: sudo apt update && sudo apt install python3.10${NC}\n"
        exit 1
    fi
else
    echo -e "${RED}× Python3 未安装${NC}"
    echo -e "${YELLOW}安装 Python3: sudo apt update && sudo apt install python3 python3-pip python3-venv${NC}\n"
    exit 1
fi

# 检查 Node.js
echo -e "${YELLOW}[2/4] 检查 Node.js...${NC}"
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "${GREEN}✓ Node.js $NODE_VERSION${NC}"
    
    # 检查版本是否 >= 16
    NODE_MAJOR=$(node -p 'process.version.split(".")[0].slice(1)')
    if [ "$NODE_MAJOR" -lt 16 ]; then
        echo -e "${RED}× Node.js 版本过低,需要 16+${NC}"
        echo -e "${YELLOW}请升级 Node.js: https://nodejs.org/${NC}\n"
        exit 1
    fi
else
    echo -e "${RED}× Node.js 未安装${NC}"
    echo -e "${YELLOW}安装 Node.js:${NC}"
    echo -e "${YELLOW}  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -${NC}"
    echo -e "${YELLOW}  sudo apt install -y nodejs${NC}\n"
    exit 1
fi

# 安装后端依赖
echo -e "\n${YELLOW}[3/4] 配置后端环境...${NC}"
cd backend

if [ ! -d "venv" ]; then
    echo -e "${CYAN}创建虚拟环境...${NC}"
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        echo -e "${RED}× 虚拟环境创建失败,请安装 python3-venv${NC}"
        echo -e "${YELLOW}  sudo apt install python3-venv${NC}\n"
        exit 1
    fi
fi

echo -e "${CYAN}激活虚拟环境并安装依赖...${NC}"
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 后端环境配置完成${NC}"
else
    echo -e "${RED}× 后端依赖安装失败${NC}"
    deactivate
    exit 1
fi

deactivate
cd ..

# 安装前端依赖
echo -e "\n${YELLOW}[4/4] 配置前端环境...${NC}"
cd frontend

echo -e "${CYAN}安装 npm 依赖 (可能需要几分钟)...${NC}"
npm install

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 前端环境配置完成${NC}"
else
    echo -e "${RED}× 前端依赖安装失败${NC}"
    exit 1
fi

cd ..

# 检查 .env 文件
echo -e "\n${YELLOW}检查配置文件...${NC}"
if [ ! -f "backend/.env" ]; then
    echo -e "${YELLOW}⚠ 未检测到 .env 文件${NC}"
    echo -e "${CYAN}正在创建默认配置文件...${NC}"
    
    # 生成随机密钥
    SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
    
    cat > backend/.env << EOF
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

# 安全配置
SECRET_KEY=$SECRET_KEY
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# 管理员配置 (请务必修改!)
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123

# 系统配置
MAX_CONCURRENT_USERS=5
HISTORY_COMPRESSION_THRESHOLD=5000
DEFAULT_USAGE_LIMIT=1
SEGMENT_SKIP_THRESHOLD=15
EOF

    echo -e "${GREEN}✓ 已创建 backend/.env 文件并生成强密钥${NC}"
    echo -e "\n${YELLOW}⚠️  重要提示:${NC}"
    echo -e "  ${YELLOW}1. 请编辑 backend/.env 文件${NC}"
    echo -e "  ${YELLOW}2. 填入您的 OPENAI_API_KEY${NC}"
    echo -e "  ${YELLOW}3. 修改 ADMIN_PASSWORD (当前为默认值 admin123)${NC}"
    echo -e "${CYAN}  nano backend/.env${NC}\n"
else
    echo -e "${GREEN}✓ 配置文件已存在${NC}"
    
    # 检查是否使用默认密钥
    if grep -q "SECRET_KEY=your-secret-key-change-this-in-production" backend/.env; then
        echo -e "\n${RED}⚠️  警告: 检测到默认 SECRET_KEY!${NC}"
        echo -e "${YELLOW}生成新的强密钥...${NC}"
        NEW_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
        sed -i "s/SECRET_KEY=your-secret-key-change-this-in-production/SECRET_KEY=$NEW_SECRET_KEY/" backend/.env
        echo -e "${GREEN}✓ 已更新 SECRET_KEY 为强随机密钥${NC}"
    fi
fi

# 完成
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✓ 环境配置完成!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${CYAN}下一步操作:${NC}"
echo -e "  1. 配置 API 密钥: ${YELLOW}nano backend/.env${NC}"
echo -e "  2. 启动后端服务: ${YELLOW}./start-backend.sh${NC}"
echo -e "  3. 启动前端服务: ${YELLOW}./start-frontend.sh${NC}"
echo -e "\n${CYAN}或使用 systemd 设置开机自启:${NC}"
echo -e "  查看文档: ${YELLOW}cat DEPLOY.md${NC}\n"

# 提示权限问题
if [ ! -x "$0" ]; then
    echo -e "${YELLOW}提示: 如需直接执行脚本,请添加执行权限:${NC}"
    echo -e "  ${CYAN}chmod +x setup.sh${NC}\n"
fi
