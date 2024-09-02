
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

# Update and install dependencies
apt update
apt install -y xvfb x11vnc xfce4 tightvncserver python3-xdg openbox curl jq
sleep 3

wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
chmod +x ./google-chrome-stable_current_amd64.deb
apt install -y ./google-chrome-stable_current_amd64.deb

sleep 3

# Create the nodepay directory
mkdir -p /root/nodepay

# Change to the nodepay directory
cd /root/nodepay

# Function to download and decode file from GitHub
download_file() {
    local filename=$1
    local url="https://api.github.com/repos/kbwpdev/nodepay/contents/${filename}?ref=main"
    
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
download_file "manifest.json" || echo "Failed to process manifest.json"
download_file "background.js" || echo "Failed to process background.js"

# Create the startup script
cat << 'EOF' > /root/start_chrome_vnc.sh
#!/bin/bash

# Set up virtual display
export DISPLAY=:99
Xvfb :99 -screen 0 1920x1080x24 &

# Start Xfce session
xfce4-session &

# Start VNC server
x11vnc -display :99 -nopw -listen localhost -xkb -ncache 10 -ncache_cr -forever &

# Start Chrome with necessary flags
google-chrome --no-sandbox --disable-gpu --disable-software-rasterizer --load-extension=/root/nodepay

# Keep the script running
while true; do
    sleep 60
done
EOF

chmod +x /root/start_chrome_vnc.sh

# Create systemd service file
cat << EOF > /etc/systemd/system/chrome-vnc.service
[Unit]
Description=Chrome and VNC Service
After=network.target

[Service]
ExecStart=/bin/bash /root/start_chrome_vnc.sh
Restart=always
User=root
Environment=DISPLAY=:99

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable chrome-vnc.service
systemctl start chrome-vnc.service

echo "Setup complete. Chrome and VNC service is now running and will start automatically on boot."
echo "You can check the status of the service with: systemctl status chrome-vnc.service"