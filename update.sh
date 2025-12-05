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

# 生成 index.html
HTML_FILE="${SCRIPT_DIR}/index.html"
cat > "$HTML_FILE" << 'HTML_EOF'
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>安装脚本集合</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Helvetica Neue', Arial, sans-serif;
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            min-height: 100vh;
            padding: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: #ffffff;
            border-radius: 12px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
            padding: 40px;
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        
        .logo {
            width: 80px;
            height: 80px;
            border-radius: 50%;
            margin: 0 auto 20px;
            display: block;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            transition: transform 0.3s ease;
        }
        
        .logo:hover {
            transform: scale(1.05);
        }
        
        h1 {
            color: #2c3e50;
            margin-bottom: 0;
            text-align: center;
            font-size: 2.5em;
            font-weight: 600;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        thead {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        th {
            padding: 16px;
            text-align: left;
            font-weight: 600;
            font-size: 1.1em;
        }
        
        th:first-child {
            width: 25%;
        }
        
        th:last-child {
            width: 75%;
        }
        
        tbody tr {
            border-bottom: 1px solid #e8e8e8;
            transition: background-color 0.2s ease;
        }
        
        tbody tr:hover {
            background-color: #f8f9fa;
        }
        
        td {
            padding: 16px;
            vertical-align: middle;
        }
        
        td:first-child {
            font-weight: 500;
        }
        
        td:first-child a {
            color: #667eea;
            text-decoration: none;
            transition: color 0.2s ease;
        }
        
        td:first-child a:hover {
            color: #764ba2;
            text-decoration: underline;
        }
        
        .command-cell {
            display: flex;
            align-items: center;
            gap: 12px;
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', 'Consolas', monospace;
            font-size: 0.9em;
            color: #2c3e50;
            word-break: break-all;
        }
        
        .copy-btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 6px;
            cursor: pointer;
            font-size: 0.85em;
            font-weight: 500;
            transition: all 0.3s ease;
            flex-shrink: 0;
            white-space: nowrap;
            box-shadow: 0 2px 8px rgba(102, 126, 234, 0.3);
        }
        
        .copy-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
        }
        
        .copy-btn:active {
            transform: translateY(0);
        }
        
        .copy-btn.copied {
            background: linear-gradient(135deg, #56ab2f 0%, #a8e063 100%);
            box-shadow: 0 2px 8px rgba(86, 171, 47, 0.3);
        }
        
        .command-text {
            flex: 1;
            background: #f8f9fa;
            padding: 10px 14px;
            border-radius: 6px;
            border: 1px solid #e8e8e8;
        }
        
        @media (max-width: 768px) {
            .container {
                padding: 20px;
            }
            
            .logo {
                width: 60px;
                height: 60px;
                margin-bottom: 15px;
            }
            
            h1 {
                font-size: 1.8em;
            }
            
            th, td {
                padding: 12px 8px;
                font-size: 0.9em;
            }
            
            .command-cell {
                flex-direction: column;
                align-items: flex-start;
            }
            
            .copy-btn {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <img src="https://avatars.githubusercontent.com/u/26536442?v=4" alt="Logo" class="logo">
            <h1>🚀 安装脚本集合</h1>
        </div>
        <table>
            <thead>
                <tr>
                    <th>安装项</th>
                    <th>安装命令</th>
                </tr>
            </thead>
            <tbody>
HTML_EOF

# 读取 README.md 并生成 HTML 表格行（跳过表头）
tail -n +3 "$README_FILE" | while IFS='|' read -r install_link command; do
    # 清理空白字符
    install_link=$(echo "$install_link" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    command=$(echo "$command" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # 提取链接文本和URL
    install_name=$(echo "$install_link" | sed -n 's/\[\(.*\)\](.*)/\1/p')
    install_url=$(echo "$install_link" | sed -n 's/\[.*\](\(.*\))/\1/p')
    
    # 提取命令（去掉代码块标记）
    command_text=$(echo "$command" | sed 's/^`//;s/`$//')
    
    # 转义 HTML 特殊字符（用于显示）
    install_name_html=$(echo "$install_name" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
    command_text_html=$(echo "$command_text" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
    
    # 转义 HTML 属性值中的特殊字符（转义 & " 和换行符）
    command_text_attr=$(echo "$command_text" | sed 's/&/\&amp;/g; s/"/\&quot;/g; s/$/\\n/g' | tr -d '\n' | sed 's/\\n$//')
    
    # 生成表格行（使用 printf 来安全处理变量）
    {
        echo "                <tr>"
        echo "                    <td><a href=\"$install_url\" target=\"_blank\">$install_name_html</a></td>"
        echo "                    <td>"
        echo "                        <div class=\"command-cell\">"
        printf "                            <button class=\"copy-btn\" data-command=\"%s\" onclick=\"copyCommand(this)\">复制</button>\n" "$command_text_attr"
        echo "                            <span class=\"command-text\">$command_text_html</span>"
        echo "                        </div>"
        echo "                    </td>"
        echo "                </tr>"
    } >> "$HTML_FILE"
done

# 添加 JavaScript 和结束标签
cat >> "$HTML_FILE" << 'HTML_EOF'
            </tbody>
        </table>
    </div>
    
    <script>
        function copyCommand(button) {
            // 从 data-command 属性获取命令
            const command = button.getAttribute('data-command');
            
            // 使用现代 Clipboard API
            navigator.clipboard.writeText(command).then(function() {
                // 成功复制
                const originalText = button.textContent;
                button.textContent = '已复制!';
                button.classList.add('copied');
                
                // 2秒后恢复原状
                setTimeout(function() {
                    button.textContent = originalText;
                    button.classList.remove('copied');
                }, 2000);
            }).catch(function(err) {
                // 降级方案：使用传统方法
                const textArea = document.createElement('textarea');
                textArea.value = command;
                textArea.style.position = 'fixed';
                textArea.style.left = '-999999px';
                document.body.appendChild(textArea);
                textArea.select();
                
                try {
                    document.execCommand('copy');
                    const originalText = button.textContent;
                    button.textContent = '已复制!';
                    button.classList.add('copied');
                    
                    setTimeout(function() {
                        button.textContent = originalText;
                        button.classList.remove('copied');
                    }, 2000);
                } catch (err) {
                    alert('复制失败，请手动复制');
                }
                
                document.body.removeChild(textArea);
            });
        }
    </script>
</body>
</html>
HTML_EOF

echo "README.md 已更新完成！"
echo "index.html 已生成完成！"
