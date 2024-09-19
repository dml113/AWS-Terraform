#/usr/bin/bash
CONTAINER_ID=$(docker ps -q --filter "ancestor=wsi-ecr")

if [ -n "$CONTAINER_ID" ]; then
    docker stop $CONTAINER_ID
    echo "Container stopped: $CONTAINER_ID"
else
    echo "No running container found for wsi-ecr."
fi

docker rm $CONTAINER_ID
echo "Container removed: $CONTAINER_ID"