#!/usr/bin/env bash

main() {

export URL=$(echo ${@} | sed 's/=/@@/' | awk -F '@@' '{print $NF}')
cat << EOF

==== ${URL} 下载内容如下 ====
```
$(curl -SsL ${URL} 2>/dev/null)
```

EOF

}

main $@
