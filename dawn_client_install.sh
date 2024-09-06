
#!/bin/bash

# Exit on any error
set -e

# Function to check if script is run as root
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

# Check if GITHUB_TOKEN is set
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN is not set. Please provide your GitHub token."
    exit 1
fi

# Main execution
check_root

# Create the nodepay directory
mkdir -p /root/dawn

# Change to the nodepay directory
cd /root/dawn

# Function to download and decode file from GitHub
download_file() {
    local filename=$1
    local url="https://api.github.com/repos/kbwpdev/dawn/contents/${filename}?ref=main"
    
    echo "Downloading $filename..."
    
    # Download file content using GitHub API and save directly to file
    if curl -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.v3.raw" -L "$url" -o "$filename"; then
        echo "Successfully downloaded: $filename"
        #echo "Content of $filename:"
        #cat "$filename"
    else
        echo "Error downloading $filename"
        return 1
    fi
}

# Download and decode files
download_file "login.py" || echo "Failed to process login.py"


tmux new-session -d -s dawn
tmux send-keys -t dawn "python3 login.py" C-m
