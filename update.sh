#!/usr/bin/env bash

#
# 根据 install 目录下的 install.sh 文件自动更新 README.md
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${SCRIPT_DIR}/install"
README_FILE="${SCRIPT_DIR}/README.md"
GITHUB_BASE="https://github.com/Xiechengqi/scripts/edit/master"
INSTALL_BASE="https://install.xiechengqi.top"

# 临时文件
TEMP_FILE=$(mktemp)
ENTRIES_FILE=$(mktemp)

# 写入标题和表格头部
cat > "$TEMP_FILE" << 'EOF'
|                           Install                            |                           Command                            |
| :----------------------------------------------------------: | :----------------------------------------------------------: |
EOF

# 查找所有 install.sh 文件并处理
find "$INSTALL_DIR" -name "install.sh" -type f | while read -r install_file; do
    # 获取相对于 install 目录的路径
    rel_path="${install_file#$INSTALL_DIR/}"
    
    # 获取目录路径（去掉 install.sh）
    dir_path="${rel_path%/install.sh}"
    
    # 生成显示名称
    # 如果路径包含多个层级，使用最后两级目录名（如 Docker/docker-compose -> docker-compose）
    # 如果只有一级，使用目录名（如 Postgres -> Postgres）
    if [[ "$dir_path" == */* ]]; then
        # 有子目录，使用最后一级目录名
        display_name=$(basename "$dir_path")
        # 如果最后一级是纯数字（如 Mysql/8），使用父目录名-数字
        if [[ "$display_name" =~ ^[0-9]+$ ]]; then
            # 获取父目录名（install/Mysql/8 -> Mysql）
            parent_dir=$(basename "$(dirname "$dir_path")")
            display_name="${parent_dir}-${display_name}"
        fi
    else
        # 直接在第一级目录下
        display_name="$dir_path"
    fi
    
    # 生成 GitHub 链接路径
    github_path="install/${rel_path}"
    
    # 生成安装 URL 路径
    install_path="install/${rel_path}"
    
    # 生成 curl 命令，默认使用 bash（注意：代码块内的 | 不需要转义）
    curl_cmd="curl -SsL ${INSTALL_BASE}/${install_path} | bash"
    
    # 检查脚本内容，判断是否需要参数
    script_content=$(cat "$install_file")
    
    # 检查是否需要参数
    needs_param=false
    param_type="version"
    
    # 检查特定的参数类型（优先检查）
    if echo "$script_content" | grep -qiE 'mainnet.*testnet.*kovan|kovan.*mainnet.*testnet|rinkey.*kovan|mainnet.*rinkey.*kovan'; then
        needs_param=true
        param_type="mainnet|testnet|kovan"
    elif echo "$script_content" | grep -qiE 'polkadot.*kusama.*westend|kusama.*polkadot.*westend'; then
        needs_param=true
        param_type="polkadot|kusama|westend"
    elif echo "$script_content" | grep -qiE 'mainnet.*testnet|testnet.*mainnet'; then
        needs_param=true
        param_type="mainnet|testnet"
    # 检查是否有 version=${1- 模式
    elif echo "$script_content" | grep -q 'version=\${1-'; then
        needs_param=true
        param_type="version"
    # 检查是否有 $1 参数使用（排除注释行，匹配 $1 后面跟非数字字符或空格）
    elif echo "$script_content" | grep -vE '^\s*#' | grep -qE '\$1\s|chainId=\$1|chain=\$1'; then
        needs_param=true
        # 如果检测到 chainId 或 chain，检查是否有特定的网络类型
        if echo "$script_content" | grep -qiE 'mainnet.*testnet.*kovan|kovan.*mainnet.*testnet|rinkey.*kovan'; then
            param_type="mainnet|testnet|kovan"
        elif echo "$script_content" | grep -qiE 'mainnet.*testnet|testnet.*mainnet'; then
            param_type="mainnet|testnet"
        else
            param_type="version"
        fi
    fi
    
    # 构建 curl 命令（代码块内的 | 不需要转义）
    if [[ "$needs_param" == true ]]; then
        if [[ "$param_type" == "version" ]]; then
            curl_cmd="curl -SsL ${INSTALL_BASE}/${install_path} | bash -s [version]"
        else
            # 代码块内的 | 不需要转义
            curl_cmd="curl -SsL ${INSTALL_BASE}/${install_path} | bash -s [${param_type}]"
        fi
    fi
    
    # 检查是否需要 sudo（如 Rust）
    if echo "$script_content" | grep -qi 'sudo bash' || [[ "$display_name" == "Rust" ]]; then
        if [[ "$needs_param" == true ]]; then
            if [[ "$param_type" == "version" ]]; then
                curl_cmd="curl -SsL ${INSTALL_BASE}/${install_path} | sudo bash -s [version]"
            else
                curl_cmd="curl -SsL ${INSTALL_BASE}/${install_path} | sudo bash -s [${param_type}]"
            fi
        else
            curl_cmd="curl -SsL ${INSTALL_BASE}/${install_path} | sudo bash"
        fi
    fi
    
    # 特殊处理：Python 使用固定版本示例
    if [[ "$display_name" == "Python" ]]; then
        curl_cmd="curl -SsL ${INSTALL_BASE}/${install_path} | bash -s 3.6"
    fi
    
    # 写入临时文件（用于排序）
    # 使用 printf 来避免反引号转义问题
    printf '%s|[%s](%s) | `%s` |\n' "${display_name}" "${display_name}" "${GITHUB_BASE}/${github_path}" "${curl_cmd}" >> "$ENTRIES_FILE"
done

# 按显示名称排序并写入表格
sort -t'|' -k1 -f "$ENTRIES_FILE" | cut -d'|' -f2- >> "$TEMP_FILE"

# 清理临时文件
rm -f "$ENTRIES_FILE"

# 替换原 README.md
mv "$TEMP_FILE" "$README_FILE"

echo "README.md 已更新完成！"
