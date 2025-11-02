# AI 学术写作助手

专业论文润色与语言优化系统

## 快速开始

### 1. 首次安装

**Windows 系统:**
```powershell
# 一键配置环境
.\setup.ps1
```

**Ubuntu/Linux 系统:**
```bash
# 添加执行权限
chmod +x setup.sh start-backend.sh start-frontend.sh

# 一键配置环境
./setup.sh
```

### 2. 配置文件

编辑 `backend/.env`:
```properties
# AI 模型配置
OPENAI_API_KEY=your_api_key
OPENAI_BASE_URL=http://localhost:8317/v1

# 管理员账户
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123

# 系统设置
MAX_CONCURRENT_USERS=5
DEFAULT_USAGE_LIMIT=1
SEGMENT_SKIP_THRESHOLD=15
```

### 3. 启动服务

**Windows 系统:**
```powershell
# 一键启动（推荐）
.\start-all.ps1

# 或分别启动
.\start-backend.ps1  # 后端 http://localhost:8000
.\start-frontend.ps1 # 前端 http://localhost:3000
```

**Ubuntu/Linux 系统:**
```bash
# 分别启动（建议使用两个终端）
./start-backend.sh   # 后端 http://localhost:8000
./start-frontend.sh  # 前端 http://localhost:3000

# 或配置 systemd 服务实现开机自启，详见 DEPLOY.md
```

## 功能特性

- **双阶段优化**: 论文润色 + 学术增强
- **智能分段**: 自动识别标题，跳过短段落
- **使用限制**: 卡密系统，可配置使用次数
- **并发控制**: 队列管理，动态调整并发数
- **实时配置**: 修改配置无需重启服务
- **数据管理**: 可视化数据库管理界面

## 管理后台

访问 `http://localhost:3000/admin` 使用管理员账户登录

### 功能模块
- 📊 **数据面板**: 用户统计、会话分析
- 👥 **用户管理**: 卡密生成、使用次数控制
- 📡 **会话监控**: 实时会话状态监控
- 💾 **数据库管理**: 查看、编辑、删除数据记录
- ⚙️ **系统配置**: 模型配置、并发设置、使用限制

## 核心配置说明

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `MAX_CONCURRENT_USERS` | 最大并发用户数 | 5 |
| `DEFAULT_USAGE_LIMIT` | 新用户默认使用次数 | 1 |
| `SEGMENT_SKIP_THRESHOLD` | 段落跳过阈值（字符数） | 15 |
| `HISTORY_COMPRESSION_THRESHOLD` | 历史压缩阈值 | 5000 |

## 项目结构

```
AI_GC/
├── backend/              # FastAPI 后端
│   ├── app/
│   │   ├── routes/      # API 路由
│   │   ├── services/    # 业务逻辑
│   │   ├── models/      # 数据模型
│   │   └── utils/       # 工具函数
│   └── .env             # 环境配置
├── frontend/             # React 前端
│   └── src/
│       ├── pages/       # 页面组件
│       └── components/  # 通用组件
└── README.md            # 本文件
```

## 部署与安全

- 📘 **生产部署指南**: 参见 [DEPLOY.md](DEPLOY.md) - 包含 Nginx、HTTPS、systemd 服务配置
- 🔒 **安全审计报告**: 参见 [SECURITY_AUDIT.md](SECURITY_AUDIT.md) - 详细的安全建议和修复方案

**⚠️ 重要提示**: 生产环境部署前，请务必:
1. 修改 `.env` 中的默认管理员密码
2. 生成强 SECRET_KEY (至少 32 字节随机字符串)
3. 填写有效的 OPENAI_API_KEY
4. 阅读安全审计报告并应用关键修复

## 常见问题

**Q: 端口被占用？**  
A: 修改启动脚本中的端口号，或停止占用进程

**Q: 配置修改后未生效？**  
A: 检查后端日志，配置应自动重载。如仍无效请重启后端

**Q: 登录失败？**  
A: 检查 `.env` 中的 `ADMIN_USERNAME` 和 `ADMIN_PASSWORD`

**Q: Ubuntu 系统部署问题？**  
A: 参考 `DEPLOY.md` 中的详细部署指南和故障排查章节

**Q: AI 调用失败？**  
A: 检查 API Key 和 Base URL 配置是否正确

## License

MIT License
