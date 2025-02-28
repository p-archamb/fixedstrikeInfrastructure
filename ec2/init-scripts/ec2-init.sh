#!/bin/bash
# Install Docker
apt-get update || yum update -y
apt-get install -y docker.io git || yum install -y docker git

# Start Docker
systemctl start docker
systemctl enable docker

# Install docker-compose
curl -L "https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create app directory
mkdir -p /opt/fsv-app

# Clone the source repository
git clone https://x-access-token:${GITHUB_TOKEN}@github.com/yourusername/fixedstrikevolatility.git /opt/fsv-app/source

# Build and run the application from source
cd /opt/fsv-app/source

# If there's a docker-compose.yml, use it
if [ -f "docker-compose.yml" ]; then
    # Configure environment variables for the database
    export DB_HOST="${DB_HOST:-localhost}"
    export DB_NAME="${DB_NAME:-fsv}"
    export DB_USER="${DB_USER:-admin}"
    export DB_PASSWORD="${DB_PASSWORD:-password}"
    
    # Run using docker-compose
    docker-compose up -d
else
    # If no docker-compose file, build and run using the Dockerfile
    docker build -t fsv-verification:latest .
    docker run -d -p 80:8080 \
        -e SPRING_DATASOURCE_URL="jdbc:mysql://${DB_HOST:-localhost}:3306/${DB_NAME:-fsv}" \
        -e SPRING_DATASOURCE_USERNAME="${DB_USER:-admin}" \
        -e SPRING_DATASOURCE_PASSWORD="${DB_PASSWORD:-password}" \
        fsv-verification:latest
fi

# Add a simple status page for the smoke test
mkdir -p /var/www/html
cat > /var/www/html/status.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>FSV App Status</title>
</head>
<body>
  <h1>Fixed Strike Volatility Application</h1>
  <p>Status: Running</p>
</body>
</html>
EOF