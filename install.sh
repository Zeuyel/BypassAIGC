#!/usr/bin/env bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VERSION="1.0.0"

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Global variables
GITHUB_USER="Zeuyel"
GITHUB_REPO="BypassAIGC"
GITHUB_BRANCH="main"
DEPLOY_DIR=""
OS_TYPE=""
APP_PORT="23110"
DB_PASSWORD=""
REDIS_PASSWORD=""
SECRET_KEY=""
ADMIN_PASSWORD=""

# CLI arguments
PORT_ARG=""
DIR_ARG=""
NON_INTERACTIVE=false

show_help() {
    cat << EOF
AI 学术写作助手 - 一键安装脚本 v${VERSION}

用法: $0 [选项]

选项:
  -p, --port <port>       应用端口 (默认: 23110)
  -d, --dir <path>        安装目录
  -y, --yes               非交互模式
  -h, --help              显示帮助

示例:
  $0                      # 交互式安装
  $0 -p 8080 -y           # 指定端口非交互式安装

访问: https://polish.zufe.top
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--port) PORT_ARG="$2"; shift 2 ;;
            -d|--dir) DIR_ARG="$2"; shift 2 ;;
            -y|--yes) NON_INTERACTIVE=true; shift ;;
            -h|--help) show_help; exit 0 ;;
            *) log_error "未知选项: $1"; show_help; exit 1 ;;
        esac
    done
}

print_header() {
    echo -e "${BLUE}"
    echo "+=================================================================+"
    echo "|                                                                 |"
    echo "|           AI 学术写作助手 - 一键安装 v${VERSION}                  |"
    echo "|                                                                 |"
    echo "+=================================================================+"
    echo -e "${NC}"
}

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        DEPLOY_DIR="${DIR_ARG:-/www/compose/ai-polish}"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        DEPLOY_DIR="${DIR_ARG:-$HOME/Applications/ai-polish}"
    else
        log_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
    log_info "检测到操作系统: $OS_TYPE"
    log_info "安装目录: $DEPLOY_DIR"
}

check_docker() {
    log_info "检查 Docker 环境..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker 未安装，请先安装: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! docker compose version &> /dev/null && ! docker-compose --version &> /dev/null; then
        log_error "Docker Compose 未安装"
        exit 1
    fi

    log_success "Docker 环境检查通过"
}

check_git() {
    if ! command -v git &> /dev/null; then
        log_error "Git 未安装，请先安装 Git"
        exit 1
    fi
}

clone_project() {
    log_info "下载项目..."

    if [[ -d "$DEPLOY_DIR" ]]; then
        log_warning "目录已存在: $DEPLOY_DIR"
        if [[ "$NON_INTERACTIVE" != true ]]; then
            read -p "是否删除并重新安装？(yes/no): " confirm
            if [[ "$confirm" != "yes" ]]; then
                log_info "安装已取消"
                exit 0
            fi
        fi
        rm -rf "$DEPLOY_DIR"
    fi

    mkdir -p "$(dirname "$DEPLOY_DIR")"
    git clone -b "$GITHUB_BRANCH" "https://github.com/${GITHUB_USER}/${GITHUB_REPO}.git" "$DEPLOY_DIR"
    log_success "项目下载完成"
}

generate_passwords() {
    log_info "生成安全密码..."

    if command -v openssl &> /dev/null; then
        DB_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)
        REDIS_PASSWORD=$(openssl rand -base64 24 | tr -d '/+=' | head -c 24)
        SECRET_KEY=$(openssl rand -base64 32 | tr -d '/+=' | head -c 32)
        ADMIN_PASSWORD=$(openssl rand -base64 16 | tr -d '/+=' | head -c 16)
    else
        DB_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)
        REDIS_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24)
        SECRET_KEY=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32)
        ADMIN_PASSWORD=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
    fi

    log_success "密码已生成"
}



write_env_file() {
    log_info "生成配置文件..."

    [[ -n "$PORT_ARG" ]] && APP_PORT="$PORT_ARG"

    cat > "$DEPLOY_DIR/.env" << EOF
# 应用配置
APP_PORT=${APP_PORT}
ALLOWED_ORIGINS=https://polish.zufe.top,http://localhost:${APP_PORT}

# 数据库配置
DB_USER=aipolish
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=aipolish
DB_HOST=postgres
DB_PORT=5432

# Redis 配置
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_HOST=redis
REDIS_PORT=6379

# 应用密钥
SECRET_KEY=${SECRET_KEY}

# 管理员账号
ADMIN_USERNAME=admin
ADMIN_PASSWORD=${ADMIN_PASSWORD}

# AI API 配置（请在服务启动后配置）
POLISH_API_KEY=
POLISH_API_BASE=https://api.openai.com/v1

# 并发限制
MAX_CONCURRENT_USERS=5
EOF

    chmod 600 "$DEPLOY_DIR/.env"
    log_success "配置文件已创建"
}

start_services() {
    log_info "启动 Docker 服务..."

    cd "$DEPLOY_DIR"

    if docker compose version &> /dev/null; then
        docker compose up -d --build
    else
        docker-compose up -d --build
    fi

    log_success "服务已启动"
}

wait_for_health() {
    log_info "等待服务健康检查 (最多 60 秒)..."

    local max_attempts=12
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))

        if curl -f http://localhost:${APP_PORT}/health &> /dev/null; then
            log_success "服务健康检查通过！"
            return 0
        fi

        if [ $attempt -lt $max_attempts ]; then
            sleep 5
        fi
    done

    log_warning "健康检查超时，但服务可能仍在启动中"
    return 1
}

print_success() {
    echo ""
    echo -e "${GREEN}+=================================================================+${NC}"
    echo -e "${GREEN}|                                                                 |${NC}"
    echo -e "${GREEN}|                    安装成功！                                    |${NC}"
    echo -e "${GREEN}|                                                                 |${NC}"
    echo -e "${GREEN}+=================================================================+${NC}"
    echo ""
    echo -e "${BLUE}安装目录:${NC}"
    echo -e "   $DEPLOY_DIR"
    echo ""
    echo -e "${BLUE}访问地址:${NC}"
    echo -e "   ${GREEN}https://polish.zufe.top${NC}"
    echo -e "   ${GREEN}http://localhost:${APP_PORT}${NC}"
    echo ""
    echo -e "${BLUE}管理后台:${NC}"
    echo -e "   ${GREEN}https://polish.zufe.top/admin${NC}"
    echo ""
    echo -e "${BLUE}管理员账号:${NC}"
    echo -e "   用户名: ${YELLOW}admin${NC}"
    echo -e "   密码:   ${YELLOW}${ADMIN_PASSWORD}${NC}"
    echo ""
    echo -e "${RED}重要提示:${NC}"
    echo -e "   1. 请保存管理员密码到安全位置"
    echo -e "   2. 请编辑配置文件设置 API Key:"
    echo -e "      ${YELLOW}vim $DEPLOY_DIR/.env${NC}"
    echo -e "      修改 ${YELLOW}POLISH_API_KEY=${NC} 为您的 API Key"
    echo -e "   3. 修改后重启服务:"
    echo -e "      ${YELLOW}cd $DEPLOY_DIR && docker compose restart${NC}"
    echo ""
    echo -e "${BLUE}常用命令:${NC}"
    echo -e "   查看日志:   ${YELLOW}cd $DEPLOY_DIR && docker compose logs -f${NC}"
    echo -e "   停止服务:   ${YELLOW}cd $DEPLOY_DIR && docker compose down${NC}"
    echo -e "   重启服务:   ${YELLOW}cd $DEPLOY_DIR && docker compose restart${NC}"
    echo ""
}

main() {
    parse_args "$@"
    print_header
    detect_os
    check_docker
    check_git
    clone_project
    generate_passwords
    write_env_file
    start_services

    if wait_for_health; then
        print_success
    else
        log_warning "安装完成，但健康检查未通过"
        log_info "请检查日志: cd $DEPLOY_DIR && docker compose logs -f"
        print_success
    fi
}

main "$@"
