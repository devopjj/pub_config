# env.j - Shell 环境配置管理工具

JJ的工作环境配置集，提供标准化的 Shell 环境、工具函数、别名和自动化脚本。

## 快速开始

### 方法 1: 一键自动安装（推荐）

适用于快速部署标准环境到新机器：

```bash
# 标准安装（自动选择最快镜像源）
curl -fsSL https://raw.githubusercontent.com/devopjj/pub_config/master/install-bashrc.sh | bash

# 强制重装
curl -fsSL https://raw.githubusercontent.com/devopjj/pub_config/master/install-bashrc.sh | bash -s -- -f

# 使用 GitHub（跳过 R2 镜像）
curl -fsSL https://raw.githubusercontent.com/devopjj/pub_config/master/install-bashrc.sh | bash -s -- --use-github
```

**install-bashrc.sh 功能说明：**
- 自动检测最新版本并下载 bashrc_bundle
- 支持 GitHub Releases 和 R2 镜像（国内加速）
- 自动创建符号链接到 `$HOME` 目录
- 版本管理：只在有新版本时更新
- 幂等性：可重复运行，不会破坏现有配置

**进阶用法：**
```bash
# 本地升级检查
cd ~/env.j
./install-bashrc.sh

# 强制全新重装
./install-bashrc.sh --force
./install-bashrc.sh -f

# 跳过二进制工具安装
./install-bashrc.sh --skip-bin

# 指定 R2 镜像地址
./install-bashrc.sh --r2-url https://your-domain.com/bashrc

# 查看帮助
./install-bashrc.sh --help
```

### 方法 2: Git Clone（用于开发）

适用于需要修改配置或版本控制的场景：

```bash
# 1. 克隆仓库
cd ~
git clone https://github.com/devopjj/pub_config.git env.j

# 2. 运行初始化脚本
cd ~/env.j
bash QUICKSTART-NEW-HOST.sh

# 或手动执行步骤
bash init-env-jim.sh          # 创建软链接
bash fix-venv-after-copy.sh   # 修复 Python 虚拟环境（如需要）
source ~/.bashrc              # 重新加载配置
```

### 应用配置

安装完成后，执行以下命令使配置生效：

```bash
# 重新加载 Shell
exec bash

# 或
source ~/.bashrc
```

## .bashrc.d 目录结构

配置文件采用模块化设计，按照数字前缀顺序加载（见 `.bashrc_loader`）：

```
~/env.j/.bashrc.d/
├── 00-09  环境变量和通用配置
│   ├── 00-common.rc         # 通用配置（非交互式 shell 也会加载）
│   ├── 00-env.sh            # 环境变量定义
│   ├── 01-vars.sh           # 变量设置
│   ├── 02-color.sh          # 颜色定义
│   └── 03-log.sh            # 日志函数
│
├── 10-19  工具初始化
│   └── 10-tools.sh          # 第三方工具加载（pyenv, nvm, etc）
│
├── 30-59  自定义函数
│   ├── 30-func.sh           # 核心函数库
│   ├── 31-geoip_functions.sh    # GeoIP 查询
│   ├── 32-func-curl.sh      # HTTP/API 工具
│   ├── 33-func-gitrepo.sh   # Git 仓库管理
│   └── 34-func-telegram_notify.sh  # Telegram 通知
│
├── 60-79  Prompt 和外观
│   ├── 50-completion.bash   # Bash 自动补全
│   └── 60-prompt.sh         # 提示符配置
│
├── 80-89  别名定义
│   ├── 80-alias.sh          # 命令别名
│   └── 80-alias_readme.md   # 别名说明文档
│
└── 90-99  本地扩展（优先级最高）
    └── 90-local.sh          # 本地个性化配置（可覆盖默认设置）
```

**加载流程：**
1. `.bash_profile` → 设置 `ENV_J_DIR`，加载 `00-common.rc`
2. `.bashrc` → 调用 `.bashrc_loader`
3. `.bashrc_loader` → 按顺序加载 `.bashrc.d/*.sh`

## 在其他机器上安装

### 自动化安装程度

| 安装内容 | 自动化程度 | 说明 |
|---------|-----------|------|
| Shell 配置文件 | ✅ 全自动 | `.bashrc`, `.bash_profile` 等自动链接 |
| 函数库和别名 | ✅ 全自动 | `.bashrc.d/` 所有模块自动加载 |
| 公共工具脚本 | ✅ 全自动 | `bin/` 目录下的工具（git-sync 等） |
| 二进制工具 | ⚠️ 可选 | 需 root 权限，可用 `--skip-bin` 跳过 |
| Python 虚拟环境 | ⚠️ 半自动 | Git clone 方式需重建，一键安装无需处理 |
| 私有仓库 (ops-toolkit) | ❌ 需配置 | 需设置 `OPS_PAT_READONLY` 环境变量 |
| SSH Keys | ❌ 手动 | 需从安全存储同步到 `~/.private.j/` |
| 凭证管理 (cred-manager) | ❌ 手动 | 需单独配置 API keys 和凭证 |

### 完整新机器设置步骤

#### 1. 基础环境准备

确保系统已安装必要依赖：

```bash
# Debian/Ubuntu
sudo apt install -y git curl python3.11 python3.11-venv python3.11-pip

# CentOS/RHEL
sudo yum install -y git curl python3.11 python3.11-pip

# macOS
brew install git curl python@3.11
```

#### 2. 执行一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/devopjj/pub_config/master/install-bashrc.sh | bash
exec bash
```

#### 3. 补充配置（按需）

**A. 私有工具仓库（可选）**

```bash
# 设置 GitHub Personal Access Token
export OPS_PAT_READONLY="ghp_xxxxxxxxxxxxx"

# 重新运行安装脚本以拉取 ops-toolkit
./install-bashrc.sh -f
```

**B. SSH 密钥同步（如需远程操作）**

```bash
# 从安全存储同步私钥
mkdir -p ~/.private.j
rsync -av user@secure-host:/path/to/keys/ ~/.private.j/
chmod 600 ~/.private.j/*
```

**C. 凭证管理工具（如需 API 集成）**

```bash
# 检查凭证管理器状态
cred-check

# 配置 AWS 凭证（示例）
aws configure --profile your_profile
```

**D. Python 虚拟环境（Git clone 方式需要）**

```bash
cd ~/env.j
bash fix-venv-after-copy.sh
```

#### 4. 验证安装

```bash
# 检查环境变量
echo $ENV_J_DIR

# 测试函数库
type sendslack  # 发送 Slack 消息函数
type git-sync   # Git 同步工具

# 检查别名
alias | grep -E '(ll|gs|gp)'

# 测试 Python 环境
~/env.j/venv/bin/python3 --version
```

### 常见问题

**Q: 安装后提示找不到命令？**
- 确保已执行 `exec bash` 或 `source ~/.bashrc`
- 检查 `$ENV_J_DIR` 是否正确设置

**Q: 无法访问 GitHub？**
- 使用 R2 镜像：`./install-bashrc.sh --use-r2`
- 或手动下载 release 文件后本地安装

**Q: Python 虚拟环境报错？**
- Git clone 方式需要重建：`bash fix-venv-after-copy.sh`
- 一键安装方式无需关心虚拟环境

**Q: 如何在多台机器间同步配置？**
- 使用 `git-sync` 命令（见下方 Git 操作部分）
- 或通过 GitHub Actions 自动同步

## Git 操作指南

### 同步配置到远程

```bash
# 方案 1: 只推送到 origin（推荐）
git sync -r origin -m "update env config"

# 方案 2: 同时同步到 GitHub
git sync -r github -m "urgent sync"

# 快捷键（已配置别名）
gh     # git push
ghf    # git push --force-with-lease
ghm    # git push origin master
```

## 项目文件说明

### 核心配置文件

- `.bashrc` - Bash 主配置文件（加载 .bashrc.d 模块）
- `.bash_profile` - 登录 Shell 初始化（设置 ENV_J_DIR）
- `.bashrc_loader` - 模块加载器（按顺序加载 .bashrc.d/）
- `.bashrc.d/` - 模块化配置目录

### 安装和初始化

- `install-bashrc.sh` - 一键安装/升级脚本（推荐）
- `QUICKSTART-NEW-HOST.sh` - 新机器快速设置向导
- `init-env-jim.sh` - 创建软链接到 $HOME
- `fix-venv-after-copy.sh` - 修复 Python 虚拟环境

### 工具和脚本

- `bin/` - 可执行工具目录
  - `git-sync` - Git 多仓库同步工具
- `scripts/` - 实用脚本集合
  - 系统监控、备份、自动化任务等

### 其他文件

- `.cred-manager/` - 凭证管理工具（需单独配置）
- `venv/` - Python 虚拟环境（用于运行脚本）
- `.private.j/` - 私密文件目录（SSH keys 等，不纳入版本控制）

## PIMA 专用配置

PIMA 环境下的特殊设置：

1. **共享网管区**: `/data/nm/` → `/NAS/nmdata/`
2. **配置文件**: 通过符号链接到 `/home/jim/gitrepo/env.j`
3. **SSH Keys**: 链接到 `/NAS/cloud/JJ-Sec/id_rsa_2048_key`

```sh
# 符号链接示例（PIMA）
.bashrc -> gitrepo/env.j/.bashrc
.vimrc -> gitrepo/env.j/.vimrc
.tmux.conf -> gitrepo/env.j/.tmux.conf
.ssh/config -> gitrepo/env.j/.ssh/config
```

## 更新日志

- **2025-10-15**: 优化环境配置、凭证管理和同步工具
- **2025-10-08**: 重构 install-bashrc.sh，增加 R2 镜像支持
- **2020-05-20**: 合并 .bash_alias 到 .commonrc（兼容 bash/zsh）
- **2020-04-12**: 添加 PIMA CA 证书

## 相关链接

- GitHub 仓库: https://github.com/devopjj/pub_config
- 私有工具: https://github.com/devopjj/ops-toolkit（需授权）

## 许可

仅供授权用户使用。
