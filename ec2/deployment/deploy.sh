#!/bin/bash
IMAGE=$1

# Pull the latest image
docker pull $IMAGE

# Stop and remove existing container if it exists
docker stop app-container || true
docker rm app-container || true

# Run the new container with appropriate environment variables
docker run -d --name app-container \
  -p 80:80 -p 443:443 \
  -e DB_HOST=$DB_HOST \
  -e DB_USER=$DB_USER \
  -e DB_PASSWORD=$DB_PASSWORD \
  -e DB_NAME=$DB_NAME \
  -v /etc/letsencrypt:/etc/letsencrypt:ro \
  $IMAGE

# Run any post-deployment tasks here
# For example, running migrations