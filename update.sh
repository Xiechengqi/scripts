#!/usr/bin/env bash

#
# 根据 install 目录下的 install.sh 文件自动更新 README.md
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${SCRIPT_DIR}/install"
README_FILE="${SCRIPT_DIR}/README.md"
GITHUB_BASE="https://github.com/Xiechengqi/scripts/edit/master"
INSTALL_BASE="https://install.xiechengqi.top"

# 获取当前北京时间
BUILD_TIME=$(TZ='Asia/Shanghai' date '+%Y-%m-%d %H:%M:%S %Z')

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
    
    # 生成 curl 命令，统一使用 sudo bash
    curl_cmd="curl -SsL ${INSTALL_BASE}/${install_path} \| sudo bash"
    
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
    <meta name="description" content="运维安装脚本集合">
    <title>运维安装脚本集合</title>
    <link rel="icon" type="image/png" href="https://avatars.githubusercontent.com/u/26536442?v=4">
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
            width: 20%;
        }
        
        th:nth-child(2) {
            width: 70%;
        }
        
        th:last-child {
            width: 10%;
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
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', 'Consolas', monospace;
            font-size: 0.9em;
            color: #2c3e50;
            word-break: break-all;
        }
        
        td:last-child {
            text-align: center;
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
            background: #f8f9fa;
            padding: 10px 14px;
            border-radius: 6px;
            border: 1px solid #e8e8e8;
            display: inline-block;
        }
        
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e8e8e8;
            color: #666;
            font-size: 0.9em;
        }
        
        .build-time {
            color: #999;
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', 'Consolas', monospace;
        }
        
        @media (max-width: 768px) {
            .container {
                padding: 20px;
            }
            
            th, td {
                padding: 12px 8px;
                font-size: 0.9em;
            }
            
            .copy-btn {
                width: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <table>
            <thead>
                <tr>
                    <th>安装项</th>
                    <th>安装命令</th>
                    <th>操作</th>
                </tr>
            </thead>
            <tbody>
HTML_EOF

# 读取 README.md 并生成 HTML 表格行（跳过表头）
tail -n +3 "$README_FILE" | while IFS= read -r line; do
    # 使用 sed 提取链接部分（第一个 | 之前的内容，去掉首尾空格）
    install_link=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/|.*//' | sed 's/[[:space:]]*$//')
    
    # 使用 sed 提取命令部分（在反引号之间的内容）
    command=$(echo "$line" | sed -n 's/.*`\(.*\)`.*/\1/p')
    
    # 跳过空行或无效行
    [ -z "$install_link" ] && continue
    [ -z "$command" ] && continue
    
    # 提取链接文本和URL
    install_name=$(echo "$install_link" | sed -n 's/\[\(.*\)\](.*)/\1/p')
    install_url=$(echo "$install_link" | sed -n 's/\[.*\](\(.*\))/\1/p')
    
    # 将转义的管道符替换为正常的管道符
    command_text=$(echo "$command" | sed 's/\\|/|/g')
    
    # 清理命令首尾的空白字符
    command_text=$(echo "$command_text" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
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
        echo "                            <span class=\"command-text\">$command_text_html</span>"
        echo "                        </div>"
        echo "                    </td>"
        echo "                    <td>"
        printf "                        <button class=\"copy-btn\" data-command=\"%s\" onclick=\"copyCommand(this)\">复制</button>\n" "$command_text_attr"
        echo "                    </td>"
        echo "                </tr>"
    } >> "$HTML_FILE"
done

# 添加 JavaScript 和结束标签
cat >> "$HTML_FILE" << HTML_EOF
            </tbody>
        </table>
        <div class="footer">
            <div class="build-time">页面生成时间: $BUILD_TIME</div>
        </div>
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
