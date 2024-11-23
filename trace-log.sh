#!/bin/bash

# Define variables
REPO_URL="https://github.com/kennethfoo24/simple-nodejs-ddtrace.git"
APP_DIR="simple-nodejs-ddtrace"
API_BASE_URL="http://localhost:3000" # Change this if the app runs on a different port

# Update and install dependencies
echo "Updating package lists and installing Node.js..."
sudo apt-get update -y
sudo apt-get install -y nodejs npm curl

# Clone the repository
if [ -d "$APP_DIR" ]; then
    echo "Repository already exists. Pulling latest changes..."
    cd $APP_DIR && git pull
else
    echo "Cloning repository..."
    git clone $REPO_URL
    cd $APP_DIR
fi

# Install npm dependencies
echo "Installing npm dependencies..."
npm install

# Start the application
echo "Starting the application..."
node app.js > mixed.log 2>&1 & # Run in the background
APP_PID=$!

# Wait for the application to start
echo "Waiting for the application to start..."
sleep 5

# Periodically call endpoints
call_endpoints() {
    while true; do
        echo "Calling /getErrorRequest endpoint..."
        curl -X GET "$API_BASE_URL/getErrorRequest"

        echo "Calling /api endpoint..."
        curl -X GET "$API_BASE_URL/api"

        echo "Waiting before the next call..."
        sleep 10 # Adjust interval as needed
    done
}

# Run endpoint calls in a background process
echo "Starting periodic endpoint calls..."
call_endpoints &

# Trap SIGINT to clean up background processes on exit
trap "echo 'Stopping processes...'; kill $APP_PID; exit" SIGINT

# Wait for the application process to end
wait $APP_PID
