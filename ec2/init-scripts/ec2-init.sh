#!/bin/bash
# Detect OS and install Docker
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "amzn" ]]; then
        # Amazon Linux
        amazon-linux-extras install docker -y
        yum install -y git
    else
        # Ubuntu/Debian
        apt-get update
        apt-get install -y docker.io git
    fi
fi

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

# Set up a simple HTTP server while we wait for the application to build
# This ensures something is responding on port 80 quickly
mkdir -p /var/www/html
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>FSV App Startup</title>
</head>
<body>
  <h1>Fixed Strike Volatility Application</h1>
  <p>Status: Starting up...</p>
</body>
</html>
EOF

# Start a simple HTTP server
if command -v python3 &>/dev/null; then
    nohup python3 -m http.server 80 --directory /var/www/html &
elif command -v python &>/dev/null; then
    nohup python -m SimpleHTTPServer 80 --directory /var/www/html &
else
    # Install Python if not available
    if [[ "$ID" == "amzn" ]]; then
        yum install -y python3
        nohup python3 -m http.server 80 --directory /var/www/html &
    else
        apt-get install -y python3
        nohup python3 -m http.server 80 --directory /var/www/html &
    fi
fi

# Build and run the application from source (in the background)
cd /opt/fsv-app/source

# Log for debugging
echo "Starting application build at $(date)" > /tmp/app-build.log

# If there's a docker-compose.yml, use it
if [ -f "docker-compose.yml" ]; then
    echo "Found docker-compose.yml, using it" >> /tmp/app-build.log
    
    # Configure environment variables for the database
    export DB_HOST="${DB_HOST:-localhost}"
    export DB_NAME="${DB_NAME:-fsv}"
    export DB_USER="${DB_USER:-admin}"
    export DB_PASSWORD="${DB_PASSWORD:-password}"
    
    # Run using docker-compose
    docker-compose up -d 2>&1 >> /tmp/app-build.log
else
    echo "No docker-compose.yml found, using Dockerfile" >> /tmp/app-build.log
    # If no docker-compose file, build and run using the Dockerfile
    docker build -t fsv-verification:latest . 2>&1 >> /tmp/app-build.log
    docker run -d -p 80:8080 \
        -e SPRING_DATASOURCE_URL="jdbc:mysql://${DB_HOST:-localhost}:3306/${DB_NAME:-fsv}" \
        -e SPRING_DATASOURCE_USERNAME="${DB_USER:-admin}" \
        -e SPRING_DATASOURCE_PASSWORD="${DB_PASSWORD:-password}" \
        fsv-verification:latest 2>&1 >> /tmp/app-build.log
fi

echo "Application build completed at $(date)" >> /tmp/app-build.log