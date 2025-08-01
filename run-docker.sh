#!/bin/bash

# Voiflo Landing Page - Docker Launch Script
# This script builds and runs the Docker container for local testing

set -e

echo "🚀 Voiflo Landing Page - Docker Setup"
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="voiflo-landing"
CONTAINER_NAME="voiflo-landing-app"
HOST_PORT=8080
CONTAINER_PORT=8080

# Parse command line arguments
COMMAND=${1:-run}

case $COMMAND in
    "build")
        echo -e "${BLUE}Building Docker image only...${NC}"
        BUILD_ONLY=true
        ;;
    "run")
        echo -e "${BLUE}Building and running Docker container...${NC}"
        BUILD_ONLY=false
        ;;
    "stop")
        echo -e "${YELLOW}Stopping container...${NC}"
        docker stop $CONTAINER_NAME 2>/dev/null || echo "Container not running"
        docker rm $CONTAINER_NAME 2>/dev/null || echo "Container already removed"
        echo -e "${GREEN}✅ Container stopped and removed${NC}"
        exit 0
        ;;
    "logs")
        echo -e "${BLUE}Showing container logs...${NC}"
        docker logs -f $CONTAINER_NAME
        exit 0
        ;;
    *)
        echo -e "${RED}Usage: $0 [build|run|stop|logs]${NC}"
        echo "  build - Build Docker image only"
        echo "  run   - Build and run container (default)"
        echo "  stop  - Stop and remove container"
        echo "  logs  - Show container logs"
        echo ""
        echo "💡 To change deployment mode (demo/sandbox/production):"
        echo "   Edit DEPLOYMENT_MODE in index.html before running"
        exit 1
        ;;
esac

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Docker is not running. Please start Docker and try again.${NC}"
        exit 1
    fi
}

# Function to stop and remove existing container
cleanup() {
    echo -e "${YELLOW}🧹 Cleaning up existing containers...${NC}"
    docker stop $CONTAINER_NAME > /dev/null 2>&1 || true
    docker rm $CONTAINER_NAME > /dev/null 2>&1 || true
}

# Function to check current deployment mode
check_deployment_mode() {
    if [ -f "index.html" ]; then
        CURRENT_MODE=$(grep "const DEPLOYMENT_MODE = " index.html | sed "s/.*const DEPLOYMENT_MODE = '\([^']*\)'.*/\1/")
        echo -e "${BLUE}📋 Current deployment mode: ${GREEN}$CURRENT_MODE${NC}"
        
        case $CURRENT_MODE in
            "demo")
                echo -e "${GREEN}   🎁 Demo mode - Users get free access${NC}"
                ;;
            "sandbox") 
                echo -e "${YELLOW}   🧪 Sandbox mode - PayPal testing${NC}"
                ;;
            "production")
                echo -e "${RED}   🚨 Production mode - Live payments${NC}"
                ;;
            *)
                echo -e "${RED}   ❌ Unknown mode: $CURRENT_MODE${NC}"
                ;;
        esac
    else
        echo -e "${RED}❌ index.html not found${NC}"
        exit 1
    fi
}

# Function to build the Docker image
build_image() {
    echo -e "${BLUE}🔨 Building Docker image...${NC}"
    docker build -t $IMAGE_NAME .
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Docker image built successfully!${NC}"
    else
        echo -e "${RED}❌ Failed to build Docker image${NC}"
        exit 1
    fi
}

# Function to run the container
run_container() {
    echo -e "${BLUE}🏃 Starting container...${NC}"
    docker run -d \
        --name $CONTAINER_NAME \
        -p $HOST_PORT:$CONTAINER_PORT \
        $IMAGE_NAME
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Container started successfully!${NC}"
    else
        echo -e "${RED}❌ Failed to start container${NC}"
        exit 1
    fi
}

# Function to wait for the application to be ready
wait_for_app() {
    echo -e "${YELLOW}⏳ Waiting for application to be ready...${NC}"
    max_attempts=30
    attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:$HOST_PORT/health > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Application is ready!${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ Application failed to start within 30 seconds${NC}"
    return 1
}

# Function to show container status
show_status() {
    echo
    echo -e "${GREEN}🎉 Success! Your application is running${NC}"
    echo "============================================"
    echo -e "📱 Application URL: ${BLUE}http://localhost:$HOST_PORT${NC}"
    echo -e "🏥 Health Check:   ${BLUE}http://localhost:$HOST_PORT/health${NC}"
    echo
    echo "📊 Container Status:"
    docker ps --filter name=$CONTAINER_NAME --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo
    echo "💡 Useful Commands:"
    echo "   View logs:     docker logs $CONTAINER_NAME"
    echo "   Stop app:      ./run-docker.sh stop"
    echo "   Change mode:   Edit DEPLOYMENT_MODE in index.html"
    echo
    echo -e "${YELLOW}Press Ctrl+C to stop the application${NC}"
}

# Function to open browser (optional)
open_browser() {
    if command -v open > /dev/null 2>&1; then
        # macOS
        open http://localhost:$HOST_PORT
    elif command -v xdg-open > /dev/null 2>&1; then
        # Linux
        xdg-open http://localhost:$HOST_PORT
    elif command -v start > /dev/null 2>&1; then
        # Windows
        start http://localhost:$HOST_PORT
    fi
}

# Main execution
main() {
    echo -e "${BLUE}Checking Docker...${NC}"
    check_docker
    
    echo -e "${BLUE}Checking deployment configuration...${NC}"
    check_deployment_mode
    
    cleanup
    build_image
    
    if [ "$BUILD_ONLY" = true ]; then
        echo -e "${GREEN}✅ Docker image built successfully!${NC}"
        echo -e "${YELLOW}💡 To run the container: $0 run${NC}"
        exit 0
    fi
    
    run_container
    
    if wait_for_app; then
        show_status
        
        # Ask if user wants to open browser
        echo -n "🌐 Open browser automatically? (y/N): "
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            open_browser
        fi
        
        # Ask if user wants to follow logs or leave container running
        echo
        echo -n "📝 Follow container logs? (y/N) [No = leave container running]: "
        read -r logs_response
        if [[ "$logs_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            echo -e "${YELLOW}📝 Following application logs (Ctrl+C to stop container):${NC}"
            echo "============================================"
            trap cleanup EXIT INT TERM
            docker logs -f $CONTAINER_NAME
        else
            echo -e "${GREEN}✅ Container left running for testing${NC}"
            echo -e "${YELLOW}💡 Use './run-docker.sh stop' to stop the container when done${NC}"
        fi
    else
        echo -e "${RED}❌ Failed to start the application${NC}"
        echo "📝 Container logs:"
        docker logs $CONTAINER_NAME
        cleanup
        exit 1
    fi
}

# Run main function
main