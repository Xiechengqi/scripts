#!/usr/bin/env /bash

binaryDownloadUrl=$1
installPath=$2
version=$3
curl -SsL ${binaryDownloadUrl} -o ${installPath}/bin/saod-${version}
chmod +x ${installPath}/bin/saod-${version}
${installPath}/bin/saod-${version} version
