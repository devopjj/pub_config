#!/bin/bash

# 优化版凭证管理器 - 支持动态环境配置
CONFIG_FILE="$HOME/.cred-manager.conf"
ENV_FILE="$HOME/.cred-manager.env"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✓ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_process() { echo -e "${CYAN}🔄 $1${NC}"; }

# 云服务提供商配置 - 定义每个云服务的字段映射
declare -A CLOUD_PROVIDERS=(
    ["aws"]="access_key_id:AWS_ACCESS_KEY_ID:required secret_access_key:AWS_SECRET_ACCESS_KEY:required region:AWS_DEFAULT_REGION:optional session_token:AWS_SESSION_TOKEN:optional"
    ["azure"]="client_id:AZURE_CLIENT_ID:required client_secret:AZURE_CLIENT_SECRET:required tenant_id:AZURE_TENANT_ID:required"
    ["gcp"]="service_account:GOOGLE_APPLICATION_CREDENTIALS:required project_id:GOOGLE_CLOUD_PROJECT:optional"
    ["cloudflare"]="api_token:CLOUDFLARE_API_TOKEN:optional api_key:CLOUDFLARE_API_KEY:optional email:CLOUDFLARE_EMAIL:optional zone_id:CLOUDFLARE_ZONE_ID:optional"
    ["team"]="test-key:TEAM_TEST_KEY:required"
)

# 默认值配置
declare -A DEFAULT_VALUES=(
    ["region"]="us-east-1"
)

# 特殊处理的字段
declare -A SPECIAL_HANDLERS=(
    ["service_account"]="handle_gcp_service_account"
)

# 通用函数：获取gopass值
get_gopass_value() {
    local path=$1
    gopass show -o "$path" 2>/dev/null
}

# 通用函数：检查gopass路径是否存在
check_gopass_path() {
    local path=$1
    gopass show "$path" >/dev/null 2>&1
}

# 特殊处理：GCP服务账号文件
handle_gcp_service_account() {
    local field_path=$1
    local temp_file="/tmp/gcp-service-account-$(date +%s).json"
    get_gopass_value "$field_path" > "$temp_file"
    chmod 600 "$temp_file"
    echo "$temp_file"
}

# 通用函数：解析云服务配置
parse_cloud_config() {
    local provider=$1
    local config="${CLOUD_PROVIDERS[$provider]}"
    
    if [[ -z "$config" ]]; then
        return 1
    fi
    
    echo "$config"
}

# 通用函数：扫描gopass中的所有profiles
scan_profiles() {
    local profiles=()
    
    # 扫描所有云服务提供商
    for provider in "${!CLOUD_PROVIDERS[@]}"; do
        # 查找该provider下的所有环境
        local provider_paths=$(gopass ls | grep -E "^$provider/" | sed "s|^$provider/||" | cut -d'/' -f1 | sort -u)
        
        for env in $provider_paths; do
            if [[ -n "$env" ]]; then
                profiles+=("$provider-$env")
            fi
        done
    done
    
    printf '%s\n' "${profiles[@]}" | sort
}

# 通用函数：解析profile获取provider和environment
parse_profile() {
    local profile=$1
    local provider=$(echo "$profile" | cut -d'-' -f1)
    local environment=$(echo "$profile" | cut -d'-' -f2-)
    
    echo "$provider $environment"
}

# 通用函数：验证profile是否完整
validate_profile() {
    local profile=$1
    read -r provider environment <<< "$(parse_profile "$profile")"
    
    local config=$(parse_cloud_config "$provider")
    if [[ -z "$config" ]]; then
        log_error "不支持的云服务提供商: $provider"
        return 1
    fi
    
    local base_path="$provider/$environment"
    local has_required=false
    
    # 检查必需字段
    IFS=' ' read -ra fields <<< "$config"
    for field_config in "${fields[@]}"; do
        IFS=':' read -r field_name env_var_name field_type <<< "$field_config"
        local field_path="$base_path/$field_name"
        
        if [[ "$field_type" == "required" ]]; then
            if check_gopass_path "$field_path"; then
                has_required=true
            else
                log_error "必需字段 '$field_path' 不存在"
                return 1
            fi
        fi
    done
    
    [[ "$has_required" == true ]]
}

# 通用函数：生成环境变量
generate_env_var() {
    local field_name=$1
    local field_path=$2
    local env_var_name=$3
    local field_type=$4
    local output_file=$5
    
    if check_gopass_path "$field_path"; then
        local value
        
        # 检查是否需要特殊处理
        if [[ -n "${SPECIAL_HANDLERS[$field_name]}" ]]; then
            local handler="${SPECIAL_HANDLERS[$field_name]}"
            value=$($handler "$field_path")
        else
            value=$(get_gopass_value "$field_path")
        fi
        
        echo "export $env_var_name=\"$value\"" >> "$output_file"
        log_success "$env_var_name 已添加"
    elif [[ "$field_type" == "required" ]]; then
        log_error "$field_name 是必需字段但不存在"
        echo "   请运行: gopass insert $field_path"
        return 1
    elif [[ -n "${DEFAULT_VALUES[$field_name]}" ]]; then
        local default_value="${DEFAULT_VALUES[$field_name]}"
        echo "export $env_var_name=\"$default_value\"" >> "$output_file"
        log_success "$env_var_name: $default_value (默认值)"
    else
        log_warning "$field_name 不存在，跳过"
    fi
    
    return 0
}

# 通用函数：为profile生成所有环境变量
generate_profile_env() {
    local profile=$1
    local output_file=$2
    
    read -r provider environment <<< "$(parse_profile "$profile")"
    local config=$(parse_cloud_config "$provider")
    local base_path="$provider/$environment"
    
    echo "# $profile 凭证" >> "$output_file"
    
    local success=true
    IFS=' ' read -ra fields <<< "$config"
    for field_config in "${fields[@]}"; do
        IFS=':' read -r field_name env_var_name field_type <<< "$field_config"
        local field_path="$base_path/$field_name"
        
        if ! generate_env_var "$field_name" "$field_path" "$env_var_name" "$field_type" "$output_file"; then
            if [[ "$field_type" == "required" ]]; then
                success=false
                break
            fi
        fi
    done
    
    echo "" >> "$output_file"
    [[ "$success" == true ]]
}

# 通用函数：输出环境变量供eval使用
output_profile_env() {
    local profile=$1
    
    read -r provider environment <<< "$(parse_profile "$profile")"
    local config=$(parse_cloud_config "$provider")
    local base_path="$provider/$environment"
    
    IFS=' ' read -ra fields <<< "$config"
    for field_config in "${fields[@]}"; do
        IFS=':' read -r field_name env_var_name field_type <<< "$field_config"
        local field_path="$base_path/$field_name"
        
        if check_gopass_path "$field_path"; then
            if [[ -n "${SPECIAL_HANDLERS[$field_name]}" ]]; then
                local handler="${SPECIAL_HANDLERS[$field_name]}"
                local value=$($handler "$field_path")
                echo "export $env_var_name=\"$value\""
            else
                local value=$(get_gopass_value "$field_path")
                echo "export $env_var_name=\"$value\""
            fi
        elif [[ -n "${DEFAULT_VALUES[$field_name]}" ]]; then
            echo "export $env_var_name=\"${DEFAULT_VALUES[$field_name]}\""
        fi
    done
}

# 检查gopass是否可用
check_gopass() {
    if ! command -v gopass &> /dev/null; then
        log_error "gopass 命令未找到，请确保已安装 gopass"
        exit 1
    fi
    
    if ! gopass ls &> /dev/null; then
        log_error "gopass 无法连接到密码存储，请检查配置"
        exit 1
    fi
    
    log_success "gopass 连接正常"
}

# 显示gopass树状结构
show_tree() {
    log_info "当前gopass结构:"
    gopass ls
}

# 列出所有profiles
list_profiles() {
    log_info "扫描可用的profiles..."
    echo ""
    
    local profiles=($(scan_profiles))
    
    if [[ ${#profiles[@]} -eq 0 ]]; then
        log_warning "未找到任何profiles"
        echo ""
        echo "请确保在gopass中设置了凭证，支持的格式："
        echo "  aws/<environment>/<field>      - AWS凭证"
        echo "  azure/<environment>/<field>    - Azure凭证"
        echo "  gcp/<environment>/<field>      - GCP凭证"
        echo "  cloudflare/<environment>/<field> - Cloudflare凭证"
        echo "  team/<environment>/<field>     - 团队凭证"
        return
    fi
    
    # 按云服务提供商分组显示
    local current_provider=""
    for profile in "${profiles[@]}"; do
        read -r provider environment <<< "$(parse_profile "$profile")"
        
        if [[ "$provider" != "$current_provider" ]]; then
            current_provider="$provider"
            case "$provider" in
                aws)
                    echo -e "${GREEN}AWS:${NC}"
                    ;;
                azure)
                    echo -e "${BLUE}Azure:${NC}"
                    ;;
                gcp)
                    echo -e "${YELLOW}GCP:${NC}"
                    ;;
                cloudflare)
                    echo -e "${CYAN}Cloudflare:${NC}"
                    ;;
                team)
                    echo -e "${CYAN}Team:${NC}"
                    ;;
                *)
                    echo -e "${NC}$provider:${NC}"
                    ;;
            esac
        fi
        
        # 验证profile是否完整
        if validate_profile "$profile" >/dev/null 2>&1; then
            echo "  ✓ $profile"
        else
            echo "  ⚠ $profile (不完整)"
        fi
    done
    
    echo ""
    echo "提示: 使用 '$0 tree' 查看完整的gopass结构"
}

# 切换profile
use_profile() {
    local profile=$1
    if validate_profile "$profile"; then
        echo "CURRENT_PROFILE=$profile" > "$CONFIG_FILE"
        generate_env_script "$profile"
        log_success "已切换到profile: $profile"
        log_info "运行以下命令之一来加载环境变量:"
        echo "  source ~/.cred-manager.env"
        echo "  eval \"\$($0 env $profile)\""
    else
        log_error "profile '$profile' 不存在或凭证缺失"
        echo ""
        echo "可用的profiles:"
        list_profiles
        exit 1
    fi
}

# 生成环境脚本
generate_env_script() {
    local profile=$1
    
    log_process "生成环境脚本..."
    
    # 创建临时文件
    local temp_file=$(mktemp)
    echo "#!/bin/bash" > "$temp_file"
    echo "# 凭证管理器环境变量 - Profile: $profile" >> "$temp_file"
    echo "# 生成时间: $(date)" >> "$temp_file"
    echo "" >> "$temp_file"
    
    if generate_profile_env "$profile" "$temp_file"; then
        # 移动到最终位置
        mv "$temp_file" "$ENV_FILE"
        chmod +x "$ENV_FILE"
        log_success "环境脚本已生成: $ENV_FILE"
    else
        rm -f "$temp_file"
        log_error "生成环境脚本失败"
        return 1
    fi
}

# 输出环境变量供eval使用
output_env_vars() {
    local profile=$1
    
    if ! validate_profile "$profile"; then
        log_error "profile '$profile' 不存在或凭证缺失" >&2
        return 1
    fi
    
    output_profile_env "$profile"
}

# 显示指定路径的密钥
show_key() {
    local path=$1
    if [ -z "$path" ]; then
        log_error "请指定密钥路径"
        echo "示例: $0 show aws/prod/access_key_id"
        return 1
    fi
    
    if check_gopass_path "$path"; then
        log_info "密钥内容 ($path):"
        gopass show "$path"
    else
        log_error "密钥路径 '$path' 不存在"
        echo "使用 '$0 tree' 查看可用路径"
    fi
}

# 显示当前profile
current_profile() {
    if [ -f "$CONFIG_FILE" ]; then
        local current=$(grep "CURRENT_PROFILE" "$CONFIG_FILE" | cut -d'=' -f2)
        if [ -n "$current" ]; then
            log_info "当前激活的profile: $current"
            
            # 显示当前环境变量状态
            echo ""
            echo "当前环境变量状态:"
            env | grep -E "^(AWS_|AZURE_|GOOGLE_|CLOUDFLARE_|TEAM_)" | sort | while read line; do
                echo "  $line"
            done
        else
            log_warning "未设置profile"
        fi
    else
        log_warning "未设置profile"
    fi
}

# 清理环境变量
clean_env() {
    log_process "清理环境变量..."
    
    # 获取所有需要清理的环境变量
    local env_vars_to_clean=(
        "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "AWS_DEFAULT_REGION" "AWS_SESSION_TOKEN"
        "AZURE_CLIENT_ID" "AZURE_CLIENT_SECRET" "AZURE_TENANT_ID"
        "GOOGLE_APPLICATION_CREDENTIALS" "GOOGLE_CLOUD_PROJECT"
        "CLOUDFLARE_API_TOKEN" "CLOUDFLARE_API_KEY" "CLOUDFLARE_EMAIL" "CLOUDFLARE_ZONE_ID"
        "TEAM_TEST_KEY"
    )
    
    # 清理环境变量
    for var in "${env_vars_to_clean[@]}"; do
        unset "$var"
    done
    
    # 清理临时文件
    rm -f /tmp/gcp-service-account-*.json
    
    # 清理环境脚本
    rm -f "$ENV_FILE"
    
    log_success "所有云凭证环境变量已清除"
}

# 显示帮助
show_help() {
    echo "凭证管理器 - 使用 gopass 管理多云凭证"
    echo ""
    echo "支持的云服务提供商:"
    echo "  • AWS        - Amazon Web Services"
    echo "  • Azure      - Microsoft Azure"
    echo "  • GCP        - Google Cloud Platform"
    echo "  • Cloudflare - Cloudflare API"
    echo "  • Team       - 团队共享密钥"
    echo ""
    echo "用法: $0 [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  list                   列出所有可用的 profiles"
    echo "  use <profile>          切换到指定 profile 并生成环境脚本"
    echo "  env <profile>          输出 export 环境变量，供 eval 使用"
    echo "  export <profile>       生成可source的环境脚本"
    echo "  current                显示当前使用的 profile"
    echo "  show <path>            显示指定路径的密钥"
    echo "  tree                   显示 gopass 树状结构"
    echo "  check                  检查gopass连接状态"
    echo "  clean                  清理环境变量"
    echo ""
    echo "Profile 格式: <provider>-<environment>"
    echo "  示例: aws-prod, azure-dev, gcp-staging, cloudflare-prod"
    echo ""
    echo "Gopass 路径结构:"
    echo "  aws/<env>/access_key_id          - AWS Access Key ID"
    echo "  aws/<env>/secret_access_key      - AWS Secret Access Key"
    echo "  aws/<env>/region                 - AWS Region (可选)"
    echo "  azure/<env>/client_id            - Azure Client ID"
    echo "  azure/<env>/client_secret        - Azure Client Secret"
    echo "  azure/<env>/tenant_id            - Azure Tenant ID"
    echo "  gcp/<env>/service_account        - GCP Service Account JSON"
    echo "  gcp/<env>/project_id             - GCP Project ID (可选)"
    echo "  cloudflare/<env>/api_token       - Cloudflare API Token"
    echo "  cloudflare/<env>/api_key         - Cloudflare API Key (可选)"
    echo "  cloudflare/<env>/email           - Cloudflare Email (可选)"
    echo "  cloudflare/<env>/zone_id         - Cloudflare Zone ID (可选)"
    echo ""
    echo "使用示例:"
    echo "  $0 list                          # 列出所有profiles"
    echo "  $0 use aws-prod                  # 切换到AWS生产环境"
    echo "  eval \"\$($0 env aws-dev)\"       # 直接加载AWS开发环境"
    echo "  $0 use cloudflare-prod           # 切换到Cloudflare生产环境"
    echo "  source ~/.cred-manager.env       # 加载生成的环境脚本"
    echo ""
}

# 主函数
main() {
    # 检查gopass可用性
    if [[ "$1" != "help" && "$1" != "--help" && "$1" != "-h" ]]; then
        check_gopass
    fi
    
    case "$1" in
        list)
            list_profiles
            ;;
        use)
            if [ -z "$2" ]; then
                log_error "请指定profile名称"
                echo ""
                list_profiles
                exit 1
            fi
            use_profile "$2"
            ;;
        env)
            if [ -z "$2" ]; then
                log_error "请指定profile名称"
                echo "使用 '$0 list' 查看可用的profiles"
                exit 1
            fi
            output_env_vars "$2"
            ;;
        export)
            if [ -z "$2" ]; then
                log_error "请指定profile名称"
                echo "使用 '$0 list' 查看可用的profiles"
                exit 1
            fi
            generate_env_script "$2"
            ;;
        current)
            current_profile
            ;;
        show)
            show_key "$2"
            ;;
        tree)
            show_tree
            ;;
        check)
            log_success "gopass 检查完成"
            ;;
        clean)
            clean_env
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            if [ -z "$1" ]; then
                show_help
            else
                log_error "未知命令 '$1'"
                echo ""
                show_help
            fi
            exit 1
            ;;
    esac
}

main "$@"