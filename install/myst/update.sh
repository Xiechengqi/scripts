#!/usr/bin/env bash

source /etc/profile

out=$(docker pull mysteriumnetwork/myst:latest)
if [[ $out != *"up to date"* ]]; then

docker pull mysteriumnetwork/myst:latest || true
docker stop myst || true
docker rm -f myst || true
docker run -itd --cap-add NET_ADMIN -p 4449:4449 -v /data/myst/data:/var/lib/mysterium-node --restart unless-stopped --name myst mysteriumnetwork/myst:latest service --agreed-terms-and-conditions
docker image prune -f
echo "Updated to latest version successfully!"

else

echo "Node up to date"

fi
