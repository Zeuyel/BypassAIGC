#!/bin/bash
# 启动前端服务

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}启动前端服务...${NC}"

# 进入前端目录
cd "$(dirname "$0")/frontend" || exit 1

# 检查 node_modules
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠ 前端依赖未安装,请先运行 ./setup.sh${NC}"
    exit 1
fi

# 检查端口是否被占用
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ 端口 3000 已被占用${NC}"
    echo -e "${CYAN}尝试停止旧进程...${NC}"
    lsof -ti:3000 | xargs kill -9 2>/dev/null
    sleep 2
fi

# 启动服务
echo -e "${GREEN}✓ 前端服务启动中...${NC}"
echo -e "${CYAN}访问地址: http://localhost:3000${NC}"
echo -e "${YELLOW}按 Ctrl+C 停止服务${NC}\n"

npm run dev
