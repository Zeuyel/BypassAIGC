#!/bin/bash
# ========================================
# AI 学术写作助手 - 开发调试脚本 (macOS)
# ⚠️ 注意：此脚本仅供开发调试使用
# 普通用户请下载并使用可执行文件版本
# ========================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# 检查操作系统
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}× 此脚本仅适用于 macOS${NC}"
    echo -e "${YELLOW}Linux/Ubuntu 请使用: ./start.sh${NC}\n"
    exit 1
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 显示菜单
show_menu() {
    clear
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}   AI 学术写作助手 - 开发管理脚本${NC}"
    echo -e "${CYAN}              (macOS 版本)${NC}"
    echo -e "${YELLOW}       ⚠️ 仅供开发调试使用${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    echo -e "${YELLOW}请选择要执行的操作:${NC}\n"
    
    echo -e "  ${GREEN}1.${NC} 环境安装配置"
    echo -e "     ${GRAY}(首次使用或需要重新配置时选择)${NC}"
    
    echo -e "\n  ${GREEN}2.${NC} 启动所有服务"
    echo -e "     ${GRAY}(同时启动前端和后端服务)${NC}"
    
    echo -e "\n  ${GREEN}3.${NC} 仅启动后端服务"
    echo -e "     ${GRAY}(启动 FastAPI 后端 - 端口 8000)${NC}"
    
    echo -e "\n  ${GREEN}4.${NC} 仅启动前端服务"
    echo -e "     ${GRAY}(启动 React 前端 - 端口 3000)${NC}"
    
    echo -e "\n  ${GREEN}5.${NC} 停止所有服务"
    echo -e "     ${GRAY}(停止所有正在运行的前后端服务)${NC}"
    
    echo -e "\n  ${GREEN}6.${NC} 验证安装"
    echo -e "     ${GRAY}(检查环境配置和依赖安装情况)${NC}"
    
    echo -e "\n  ${GREEN}7.${NC} 验证数据库"
    echo -e "     ${GRAY}(检查数据库配置和连接状态)${NC}"
    
    echo -e "\n  ${GREEN}8.${NC} 故障排查"
    echo -e "     ${GRAY}(生成诊断报告，帮助定位问题)${NC}"
    
    echo -e "\n  ${GREEN}9.${NC} 清理环境"
    echo -e "     ${GRAY}(清理临时文件、日志或重置环境)${NC}"
    
    echo -e "\n  ${GREEN}0.${NC} 退出"
    
    echo -e "\n${CYAN}========================================${NC}"
    echo -en "${YELLOW}输入选项编号: ${NC}"
}

# 1. 环境安装配置
setup_environment() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}开始环境配置 (macOS)...${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    # 检查 Homebrew
    echo -e "${YELLOW}[1/6] 检查 Homebrew...${NC}"
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}⚠ Homebrew 未安装，正在安装...${NC}"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [ $? -ne 0 ]; then
            echo -e "${RED}× Homebrew 安装失败${NC}"
            read -p "按回车键返回菜单..."
            return
        fi
    else
        echo -e "${GREEN}✓ Homebrew 已安装${NC}"
    fi
    
    # 检查并安装 Python
    echo -e "\n${YELLOW}[2/6] 检查 Python...${NC}"
    if command -v python3 &> /dev/null; then
        python_version=$(python3 --version 2>&1)
        if [[ $python_version =~ Python[[:space:]]([0-9]+)\.([0-9]+) ]]; then
            major=${BASH_REMATCH[1]}
            minor=${BASH_REMATCH[2]}
            if [ "$major" -ge 3 ] && [ "$minor" -ge 10 ]; then
                echo -e "${GREEN}✓ $python_version${NC}"
            else
                echo -e "${YELLOW}⚠ Python 版本过低，正在安装 Python 3.10...${NC}"
                brew install python@3.10
            fi
        fi
    else
        echo -e "${YELLOW}⚠ Python 未安装，正在通过 Homebrew 安装...${NC}"
        brew install python@3.10
    fi
    
    # 检查并安装 Node.js
    echo -e "\n${YELLOW}[3/6] 检查 Node.js...${NC}"
    if command -v node &> /dev/null; then
        node_version=$(node --version 2>&1)
        if [[ $node_version =~ v([0-9]+) ]]; then
            major=${BASH_REMATCH[1]}
            if [ "$major" -ge 16 ]; then
                echo -e "${GREEN}✓ Node.js $node_version${NC}"
            else
                echo -e "${YELLOW}⚠ Node.js 版本过低，正在更新...${NC}"
                brew install node
            fi
        fi
    else
        echo -e "${YELLOW}⚠ Node.js 未安装，正在通过 Homebrew 安装...${NC}"
        brew install node
    fi
    
    # 创建后端虚拟环境
    echo -e "\n${YELLOW}[4/6] 配置后端环境...${NC}"
    cd "$SCRIPT_DIR/backend"
    
    if [ ! -d "venv" ]; then
        echo -e "${CYAN}创建 Python 虚拟环境...${NC}"
        python3 -m venv venv
        if [ $? -ne 0 ]; then
            echo -e "${RED}× 创建虚拟环境失败${NC}"
            read -p "按回车键返回菜单..."
            return
        fi
    else
        echo -e "${CYAN}虚拟环境已存在${NC}"
    fi
    
    echo -e "${CYAN}安装后端依赖...${NC}"
    source venv/bin/activate
    pip install -r requirements.txt
    if [ $? -ne 0 ]; then
        deactivate
        echo -e "${RED}× 安装后端依赖失败${NC}"
        read -p "按回车键返回菜单..."
        return
    fi
    deactivate
    echo -e "${GREEN}✓ 后端环境配置完成${NC}"
    
    # 安装前端依赖
    echo -e "\n${YELLOW}[5/6] 配置前端环境...${NC}"
    cd "$SCRIPT_DIR/frontend"
    
    if [ ! -d "node_modules" ]; then
        echo -e "${CYAN}安装前端依赖（这可能需要几分钟）...${NC}"
        npm install
        if [ $? -ne 0 ]; then
            echo -e "${RED}× 安装前端依赖失败${NC}"
            read -p "按回车键返回菜单..."
            return
        fi
    else
        echo -e "${CYAN}前端依赖已安装${NC}"
    fi
    echo -e "${GREEN}✓ 前端环境配置完成${NC}"
    
    # 生成配置文件
    echo -e "\n${YELLOW}[6/6] 配置文件...${NC}"
    cd "$SCRIPT_DIR/backend"
    
    if [ ! -f ".env" ]; then
        echo -e "${CYAN}生成默认配置文件...${NC}"
        cat > .env << 'EOF'
# 数据库配置
DATABASE_URL=sqlite:///./ai_polish.db

# Redis 配置
REDIS_URL=redis://localhost:6379/0

# OpenAI API 配置
OPENAI_API_KEY=your-api-key-here
OPENAI_BASE_URL=http://IP:PORT/v1

# 第一阶段模型配置 (论文润色) - 推荐使用 gemini-2.5-pro
POLISH_MODEL=gemini-2.5-pro
POLISH_API_KEY=your-api-key-here
POLISH_BASE_URL=http://IP:PORT/v1

# 第二阶段模型配置 (原创性增强) - 推荐使用 gemini-2.5-pro
ENHANCE_MODEL=gemini-2.5-pro
ENHANCE_API_KEY=your-api-key-here
ENHANCE_BASE_URL=http://IP:PORT/v1

# 感情文章润色模型配置 - 推荐使用 gemini-2.5-pro
EMOTION_MODEL=gemini-2.5-pro
EMOTION_API_KEY=your-api-key-here
EMOTION_BASE_URL=http://IP:PORT/v1

# 并发配置
MAX_CONCURRENT_USERS=5

# 会话压缩配置
HISTORY_COMPRESSION_THRESHOLD=2000
COMPRESSION_MODEL=gemini-2.5-pro
COMPRESSION_API_KEY=your-api-key-here
COMPRESSION_BASE_URL=http://IP:PORT/v1

# JWT 密钥（请修改为随机字符串）
SECRET_KEY=your-secret-key-change-this-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# 管理员账户（生产环境请修改密码）
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123
DEFAULT_USAGE_LIMIT=1
SEGMENT_SKIP_THRESHOLD=15
EOF
        echo -e "${GREEN}✓ 配置文件已生成: backend/.env${NC}"
        echo -e "${YELLOW}⚠ 请编辑 backend/.env 填入您的 API 密钥${NC}"
    else
        echo -e "${GREEN}✓ 配置文件已存在: backend/.env${NC}"
    fi
    
    cd "$SCRIPT_DIR"
    
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ 环境配置完成!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "\n${YELLOW}下一步:${NC}"
    echo -e "1. 编辑 backend/.env 填入 API 密钥"
    echo -e "2. 选择选项 2 启动所有服务"
    echo -e "\n${GRAY}按回车键返回菜单...${NC}"
    read
}

# 2. 启动所有服务
start_all_services() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}启动所有服务 (macOS)...${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    # 检查环境
    if [ ! -d "$SCRIPT_DIR/backend/venv" ]; then
        echo -e "${RED}× 后端虚拟环境不存在${NC}"
        echo -e "${YELLOW}请先选择选项 1 进行环境配置${NC}\n"
        read -p "按回车键返回菜单..."
        return
    fi
    
    if [ ! -d "$SCRIPT_DIR/frontend/node_modules" ]; then
        echo -e "${RED}× 前端依赖未安装${NC}"
        echo -e "${YELLOW}请先选择选项 1 进行环境配置${NC}\n"
        read -p "按回车键返回菜单..."
        return
    fi
    
    # 检查是否安装了 tmux
    local USE_TMUX=false
    if command -v tmux &> /dev/null; then
        USE_TMUX=true
        echo -e "${CYAN}将使用 tmux 启动服务${NC}"
    else
        echo -e "${YELLOW}未检测到 tmux，建议安装以便后台运行${NC}"
        echo -e "${CYAN}安装命令: brew install tmux${NC}"
        echo -e "${CYAN}将使用 nohup 后台运行${NC}\n"
    fi
    
    # 启动后端
    echo -e "${YELLOW}[1/2] 启动后端服务...${NC}"
    
    if [ "$USE_TMUX" = true ]; then
        # 检查会话是否已存在
        if tmux has-session -t bypassaigc-backend 2>/dev/null; then
            echo -e "${YELLOW}⚠ 后端会话已存在，先停止旧会话${NC}"
            tmux kill-session -t bypassaigc-backend
            sleep 1
        fi
        
        tmux new-session -d -s bypassaigc-backend "cd '$SCRIPT_DIR/backend' && source venv/bin/activate && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
        echo -e "${GREEN}✓ 后端服务已在 tmux 会话中启动${NC}"
        echo -e "${CYAN}  查看后端: tmux attach -t bypassaigc-backend${NC}"
    else
        cd "$SCRIPT_DIR/backend"
        nohup bash -c "source venv/bin/activate && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload" > backend.log 2>&1 &
        BACKEND_PID=$!
        echo $BACKEND_PID > "$SCRIPT_DIR/backend.pid"
        echo -e "${GREEN}✓ 后端服务已启动 (PID: $BACKEND_PID)${NC}"
        echo -e "${CYAN}  查看日志: tail -f backend/backend.log${NC}"
        cd "$SCRIPT_DIR"
    fi
    
    # 等待后端启动
    echo -e "${CYAN}等待后端服务启动...${NC}"
    sleep 5
    
    # 启动前端
    echo -e "${YELLOW}[2/2] 启动前端服务...${NC}"
    
    if [ "$USE_TMUX" = true ]; then
        # 检查会话是否已存在
        if tmux has-session -t bypassaigc-frontend 2>/dev/null; then
            echo -e "${YELLOW}⚠ 前端会话已存在，先停止旧会话${NC}"
            tmux kill-session -t bypassaigc-frontend
            sleep 1
        fi
        
        tmux new-session -d -s bypassaigc-frontend "cd '$SCRIPT_DIR/frontend' && npm run dev"
        echo -e "${GREEN}✓ 前端服务已在 tmux 会话中启动${NC}"
        echo -e "${CYAN}  查看前端: tmux attach -t bypassaigc-frontend${NC}"
    else
        cd "$SCRIPT_DIR/frontend"
        nohup npm run dev > frontend.log 2>&1 &
        FRONTEND_PID=$!
        echo $FRONTEND_PID > "$SCRIPT_DIR/frontend.pid"
        echo -e "${GREEN}✓ 前端服务已启动 (PID: $FRONTEND_PID)${NC}"
        echo -e "${CYAN}  查看日志: tail -f frontend/frontend.log${NC}"
        cd "$SCRIPT_DIR"
    fi
    
    # 完成
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ 系统启动完成!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${CYAN}访问地址:${NC}"
    echo -e "  前端: ${YELLOW}http://localhost:3000${NC}"
    echo -e "  后端: ${YELLOW}http://localhost:8000${NC}"
    echo -e "  管理: ${YELLOW}http://localhost:3000/admin${NC}"
    echo -e "  文档: ${YELLOW}http://localhost:8000/docs${NC}"
    echo -e "${GREEN}========================================${NC}\n"
    
    if [ "$USE_TMUX" = true ]; then
        echo -e "${CYAN}管理 tmux 会话:${NC}"
        echo -e "  查看所有: ${YELLOW}tmux ls${NC}"
        echo -e "  进入后端: ${YELLOW}tmux attach -t bypassaigc-backend${NC}"
        echo -e "  进入前端: ${YELLOW}tmux attach -t bypassaigc-frontend${NC}"
        echo -e "  退出会话: ${YELLOW}Cmd+B 然后按 D${NC}"
    else
        echo -e "${CYAN}停止服务: ${YELLOW}选择选项 5${NC}"
    fi
    
    # 尝试在浏览器中打开
    echo -e "\n${CYAN}正在打开浏览器...${NC}"
    sleep 2
    if command -v open &> /dev/null; then
        open http://localhost:3000
    fi
    
    echo -e "\n${GRAY}按回车键返回菜单...${NC}"
    read
}

# 3. 启动后端服务
start_backend() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}启动后端服务...${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    if [ ! -d "$SCRIPT_DIR/backend/venv" ]; then
        echo -e "${RED}× 虚拟环境不存在${NC}"
        echo -e "${YELLOW}请先选择选项 1 进行环境配置${NC}\n"
        read -p "按回车键返回菜单..."
        return
    fi
    
    if [ ! -f "$SCRIPT_DIR/backend/.env" ]; then
        echo -e "${RED}× 配置文件不存在${NC}"
        echo -e "${YELLOW}请先选择选项 1 进行环境配置${NC}\n"
        read -p "按回车键返回菜单..."
        return
    fi
    
    # 检查端口
    if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ 端口 8000 已被占用${NC}"
        echo -e "${CYAN}尝试停止旧进程...${NC}"
        lsof -ti:8000 | xargs kill -9 2>/dev/null
        sleep 2
    fi
    
    echo -e "${CYAN}服务地址: http://localhost:8000${NC}"
    echo -e "${CYAN}API 文档: http://localhost:8000/docs${NC}"
    echo -e "${YELLOW}按 Ctrl+C 停止服务${NC}\n"
    
    cd "$SCRIPT_DIR/backend"
    source venv/bin/activate
    uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
}

# 4. 启动前端服务
start_frontend() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}启动前端服务...${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    if [ ! -d "$SCRIPT_DIR/frontend/node_modules" ]; then
        echo -e "${RED}× 前端依赖未安装${NC}"
        echo -e "${YELLOW}请先选择选项 1 进行环境配置${NC}\n"
        read -p "按回车键返回菜单..."
        return
    fi
    
    # 检查端口
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ 端口 3000 已被占用${NC}"
        echo -e "${CYAN}尝试停止旧进程...${NC}"
        lsof -ti:3000 | xargs kill -9 2>/dev/null
        sleep 2
    fi
    
    echo -e "${CYAN}服务地址: http://localhost:3000${NC}"
    echo -e "${YELLOW}按 Ctrl+C 停止服务${NC}\n"
    
    cd "$SCRIPT_DIR/frontend"
    npm run dev
}

# 5. 停止所有服务
stop_all_services() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}停止所有服务...${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    local stopped=false
    
    # 停止 tmux 会话
    if command -v tmux &> /dev/null; then
        if tmux has-session -t bypassaigc-backend 2>/dev/null; then
            tmux kill-session -t bypassaigc-backend
            echo -e "${GREEN}✓ 已停止后端 tmux 会话${NC}"
            stopped=true
        fi
        
        if tmux has-session -t bypassaigc-frontend 2>/dev/null; then
            tmux kill-session -t bypassaigc-frontend
            echo -e "${GREEN}✓ 已停止前端 tmux 会话${NC}"
            stopped=true
        fi
    fi
    
    # 停止 PID 文件中的进程
    if [ -f "$SCRIPT_DIR/backend.pid" ]; then
        pid=$(cat "$SCRIPT_DIR/backend.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            echo -e "${GREEN}✓ 已停止后端服务 (PID: $pid)${NC}"
            stopped=true
        fi
        rm "$SCRIPT_DIR/backend.pid"
    fi
    
    if [ -f "$SCRIPT_DIR/frontend.pid" ]; then
        pid=$(cat "$SCRIPT_DIR/frontend.pid")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null
            echo -e "${GREEN}✓ 已停止前端服务 (PID: $pid)${NC}"
            stopped=true
        fi
        rm "$SCRIPT_DIR/frontend.pid"
    fi
    
    # 通过端口停止
    if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        lsof -ti:8000 | xargs kill -9 2>/dev/null
        echo -e "${GREEN}✓ 已停止端口 8000 上的进程${NC}"
        stopped=true
    fi
    
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        lsof -ti:3000 | xargs kill -9 2>/dev/null
        echo -e "${GREEN}✓ 已停止端口 3000 上的进程${NC}"
        stopped=true
    fi
    
    if [ "$stopped" = false ]; then
        echo -e "${YELLOW}⚠ 未发现运行中的服务${NC}"
    else
        echo -e "\n${GREEN}✓ 所有服务已停止${NC}"
    fi
    
    echo -e "\n${GRAY}按回车键返回菜单...${NC}"
    read
}

# 6. 验证安装
verify_installation() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}验证安装状态 (macOS)...${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    local all_ok=true
    
    # 检查 Homebrew
    echo -e "${YELLOW}[1/8] 检查 Homebrew...${NC}"
    if command -v brew &> /dev/null; then
        echo -e "${GREEN}✓ Homebrew 已安装${NC}"
    else
        echo -e "${YELLOW}⚠ Homebrew 未安装${NC}"
    fi
    
    # 检查 Python
    echo -e "${YELLOW}[2/8] 检查 Python...${NC}"
    if command -v python3 &> /dev/null; then
        python_version=$(python3 --version 2>&1)
        echo -e "${GREEN}✓ $python_version${NC}"
    else
        echo -e "${RED}× Python 未安装${NC}"
        all_ok=false
    fi
    
    # 检查 Node.js
    echo -e "${YELLOW}[3/8] 检查 Node.js...${NC}"
    if command -v node &> /dev/null; then
        node_version=$(node --version 2>&1)
        echo -e "${GREEN}✓ Node.js $node_version${NC}"
    else
        echo -e "${RED}× Node.js 未安装${NC}"
        all_ok=false
    fi
    
    # 检查后端虚拟环境
    echo -e "${YELLOW}[4/8] 检查后端虚拟环境...${NC}"
    if [ -d "$SCRIPT_DIR/backend/venv" ]; then
        echo -e "${GREEN}✓ 虚拟环境存在${NC}"
    else
        echo -e "${RED}× 虚拟环境不存在${NC}"
        all_ok=false
    fi
    
    # 检查前端依赖
    echo -e "${YELLOW}[5/8] 检查前端依赖...${NC}"
    if [ -d "$SCRIPT_DIR/frontend/node_modules" ]; then
        echo -e "${GREEN}✓ 前端依赖已安装${NC}"
    else
        echo -e "${RED}× 前端依赖未安装${NC}"
        all_ok=false
    fi
    
    # 检查配置文件
    echo -e "${YELLOW}[6/8] 检查配置文件...${NC}"
    if [ -f "$SCRIPT_DIR/backend/.env" ]; then
        echo -e "${GREEN}✓ 配置文件存在${NC}"
        
        # 检查必要的配置项
        if grep -q "OPENAI_API_KEY=your-api-key-here" "$SCRIPT_DIR/backend/.env"; then
            echo -e "${YELLOW}⚠ 警告: API 密钥未配置${NC}"
        fi
    else
        echo -e "${RED}× 配置文件不存在${NC}"
        all_ok=false
    fi
    
    # 检查端口占用
    echo -e "${YELLOW}[7/8] 检查端口占用...${NC}"
    if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ 端口 8000 已被占用${NC}"
    else
        echo -e "${GREEN}✓ 端口 8000 可用${NC}"
    fi
    
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ 端口 3000 已被占用${NC}"
    else
        echo -e "${GREEN}✓ 端口 3000 可用${NC}"
    fi
    
    # 检查数据库
    echo -e "${YELLOW}[8/8] 检查数据库...${NC}"
    if [ -f "$SCRIPT_DIR/backend/ai_polish.db" ]; then
        echo -e "${GREEN}✓ 数据库文件存在${NC}"
    else
        echo -e "${YELLOW}⚠ 数据库未初始化（首次启动时会自动创建）${NC}"
    fi
    
    # 总结
    echo -e "\n${CYAN}========================================${NC}"
    if [ "$all_ok" = true ]; then
        echo -e "${GREEN}✓ 所有检查通过!${NC}"
    else
        echo -e "${YELLOW}⚠ 部分检查未通过${NC}"
        echo -e "${YELLOW}建议选择选项 1 重新配置环境${NC}"
    fi
    echo -e "${CYAN}========================================${NC}\n"
    
    echo -e "${GRAY}按回车键返回菜单...${NC}"
    read
}

# 7. 验证数据库
verify_database() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}验证数据库...${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    if [ ! -d "$SCRIPT_DIR/backend/venv" ]; then
        echo -e "${RED}× 虚拟环境不存在${NC}"
        echo -e "${YELLOW}请先选择选项 1 进行环境配置${NC}\n"
        read -p "按回车键返回菜单..."
        return
    fi
    
    echo -e "${CYAN}运行数据库验证脚本...${NC}"
    cd "$SCRIPT_DIR/backend"
    source venv/bin/activate
    python init_db.py
    local exit_code=$?
    deactivate
    cd "$SCRIPT_DIR"
    
    if [ $exit_code -eq 0 ]; then
        echo -e "\n${GREEN}✓ 数据库验证成功${NC}"
    else
        echo -e "\n${RED}× 数据库验证失败${NC}"
    fi
    
    echo -e "\n${GRAY}按回车键返回菜单...${NC}"
    read
}

# 8. 故障排查
troubleshoot() {
    if [ ! -f "$SCRIPT_DIR/troubleshoot.sh" ]; then
        echo -e "\n${RED}× 故障排查脚本不存在${NC}\n"
        read -p "按回车键返回菜单..."
        return
    fi
    
    bash "$SCRIPT_DIR/troubleshoot.sh"
    read -p "按回车键返回菜单..."
}

# 9. 清理环境
cleanup() {
    if [ ! -f "$SCRIPT_DIR/cleanup-macos.sh" ]; then
        echo -e "\n${RED}× 清理脚本不存在${NC}\n"
        read -p "按回车键返回菜单..."
        return
    fi
    
    bash "$SCRIPT_DIR/cleanup-macos.sh"
    read -p "按回车键返回菜单..."
}

# 主程序
main() {
    # 如果提供了命令行参数，直接执行对应功能
    if [ $# -gt 0 ]; then
        case "$1" in
            1) setup_environment ;;
            2) start_all_services ;;
            3) start_backend ;;
            4) start_frontend ;;
            5) stop_all_services ;;
            6) verify_installation ;;
            7) verify_database ;;
            8) troubleshoot ;;
            9) cleanup ;;
            *)
                echo -e "${RED}无效的选项: $1${NC}"
                exit 1
                ;;
        esac
        exit 0
    fi
    
    # 交互式菜单
    while true; do
        show_menu
        read choice
        
        case "$choice" in
            1) setup_environment ;;
            2) start_all_services ;;
            3) start_backend ;;
            4) start_frontend ;;
            5) stop_all_services ;;
            6) verify_installation ;;
            7) verify_database ;;
            8) troubleshoot ;;
            9) cleanup ;;
            0)
                echo -e "\n${CYAN}再见!${NC}\n"
                exit 0
                ;;
            *)
                echo -e "\n${RED}无效的选项，请重新选择${NC}"
                sleep 2
                ;;
        esac
    done
}

# 运行主程序
main "$@"
