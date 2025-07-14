#!/bin/bash

# 优化的自动加载凭证管理器
export PATH="$PATH:$HOME/.cred-manager"

# 配置文件路径
CRED_CONFIG="$HOME/.cred-manager.conf"
CRED_ENV="$HOME/.cred-manager.env"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 通用日志函数
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✓ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_process() { echo -e "${CYAN}🔄 $1${NC}"; }

# 获取所有可能的环境变量名
get_all_env_vars() {
    echo "AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION AWS_SESSION_TOKEN"
    echo "AZURE_CLIENT_ID AZURE_CLIENT_SECRET AZURE_TENANT_ID"
    echo "GOOGLE_APPLICATION_CREDENTIALS GOOGLE_CLOUD_PROJECT"
    echo "CLOUDFLARE_API_TOKEN CLOUDFLARE_API_KEY CLOUDFLARE_EMAIL CLOUDFLARE_ZONE_ID"
    echo "TEAM_TEST_KEY"
}

# 检查是否有任何凭证环境变量
has_any_credentials() {
    local env_vars=$(get_all_env_vars)
    for var in $env_vars; do
        if [[ -n "${!var}" ]]; then
            return 0
        fi
    done
    return 1
}

# 显示当前环境变量
show_current_env() {
    local env_vars=$(env | grep -E "^(AWS_|AZURE_|GOOGLE_|CLOUDFLARE_|TEAM_)" | sort)
    if [[ -n "$env_vars" ]]; then
        echo "当前环境变量:"
        echo "$env_vars" | while read line; do
            echo "  $line"
        done
    else
        echo "当前环境变量: 未设置"
    fi
}

# 获取动态profiles用于自动补全
get_dynamic_profiles() {
    if [[ -f "$HOME/.cred-manager/cred-manager.sh" ]]; then
        "$HOME/.cred-manager/cred-manager.sh" list 2>/dev/null | grep -E "^\s*[✓⚠]\s+" | awk '{print $2}' || echo ""
    fi
}

# 自动补全功能
_cred_manager_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    opts="list use current env export show tree check clean help"
    
    case "${prev}" in
        use|env|export)
            local profiles=$(get_dynamic_profiles)
            COMPREPLY=( $(compgen -W "${profiles}" -- ${cur}) )
            return 0
            ;;
        show)
            # 提供常用路径示例
            local paths="aws/prod/access_key_id azure/prod/client_id gcp/prod/service_account cloudflare/prod/api_token"
            COMPREPLY=( $(compgen -W "${paths}" -- ${cur}) )
            return 0
            ;;
        *)
            COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            return 0
            ;;
    esac
}

# 检查cred-manager.sh是否存在
if [[ -f "$HOME/.cred-manager/cred-manager.sh" ]]; then
    complete -F _cred_manager_completion cred-manager.sh
fi

# 修改这些别名定义（大约在第 85-92 行）
alias cred='$HOME/.cred-manager/cred-manager.sh'
alias cred-use='$HOME/.cred-manager/cred-manager.sh use'
alias cred-list='$HOME/.cred-manager/cred-manager.sh list'
alias cred-current='$HOME/.cred-manager/cred-manager.sh current'
alias cred-show='$HOME/.cred-manager/cred-manager.sh show'
alias cred-tree='$HOME/.cred-manager/cred-manager.sh tree'
alias cred-check='$HOME/.cred-manager/cred-manager.sh check'
alias cred-clean='$HOME/.cred-manager/cred-manager.sh clean'
alias cred-help='$HOME/.cred-manager/cred-manager.sh help'

# 加载环境变量的函数
cred-load() {
    if [[ -f "$CRED_ENV" ]]; then
        source "$CRED_ENV"
        log_success "环境变量已从 $CRED_ENV 加载"
        show_current_env
    else
        log_warning "没有找到环境变量文件"
        echo "请先运行: cred use <profile>"
    fi
}

# 快速切换并加载环境变量
cred-switch() {
    if [[ -z "$1" ]]; then
        log_error "请指定profile名称"
        echo "可用的profiles:"
        cred-manager.sh list
        return 1
    fi
    
    log_process "切换到 profile: $1"
    cred-manager.sh use "$1"
    
    if [[ $? -eq 0 ]]; then
        log_process "加载环境变量..."
        cred-load
    else
        log_error "切换失败"
        return 1
    fi
}

# 使用eval方式加载环境变量（推荐）
cred-eval() {
    if [[ -z "$1" ]]; then
        log_error "请指定profile名称"
        echo "可用的profiles:"
        cred-manager.sh list
        return 1
    fi
    
    log_process "通过eval方式加载 profile: $1"
    
    local env_output
    env_output=$(cred-manager.sh env "$1" 2>/dev/null)
    
    if [[ $? -eq 0 && -n "$env_output" ]]; then
        eval "$env_output"
        log_success "环境变量已通过eval方式加载"
        
        # 更新配置文件
        echo "CURRENT_PROFILE=$1" > "$CRED_CONFIG"
        show_current_env
    else
        log_error "加载失败，请检查profile是否存在"
        return 1
    fi
}

# 智能加载函数
cred-auto() {
    if [[ -f "$CRED_CONFIG" ]]; then
        local current_profile=$(grep "CURRENT_PROFILE" "$CRED_CONFIG" | cut -d'=' -f2)
        if [[ -n "$current_profile" ]]; then
            log_process "自动加载当前profile: $current_profile"
            cred-eval "$current_profile"
        else
            log_warning "未找到当前profile配置"
        fi
    else
        log_warning "未找到配置文件，请先设置profile"
        echo "使用: cred use <profile>"
    fi
}

# 显示当前环境变量状态
cred-status() {
    log_info "当前凭证状态:"
    
    # 显示当前profile
    if [[ -f "$CRED_CONFIG" ]]; then
        local current_profile=$(grep "CURRENT_PROFILE" "$CRED_CONFIG" | cut -d'=' -f2)
        if [[ -n "$current_profile" ]]; then
            echo "  Profile: $current_profile"
        fi
    fi
    
    # 显示环境变量
    show_current_env
}

# 清理环境变量
cred-reset() {
    log_process "清理所有凭证环境变量..."
    
    local env_vars=$(get_all_env_vars)
    for var in $env_vars; do
        unset "$var"
    done
    
    # 清理临时文件
    rm -f /tmp/gcp-service-account-*.json
    
    log_success "所有云凭证环境变量已清除"
}