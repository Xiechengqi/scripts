#!/usr/bin/env bash

main() {

# clean service
cd /etc/supervisor/conf.d && EXEC "pwd" && EXEC "rm -f ./*" && EXEC "supervisorctl update" && EXEC "cd -"

}

main $@
