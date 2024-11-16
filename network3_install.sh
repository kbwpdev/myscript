#!/bin/bash

# Allow traffic on port 8080
sudo ufw allow 8080

# Install net-tools
sudo apt-get install -y net-tools

# Download and extract ubuntu-node
wget https://network3.io/ubuntu-node-v2.1.0.tar
tar -xf ubuntu-node-v2.1.0.tar
cd ubuntu-node

# Run manager.sh
sudo bash manager.sh up

sleep 5

# Get the key and store it in p_param
p_param=$(sudo bash manager.sh key)
echo "p_param: $p_param"

# Get server's public IP
server_ip=$(curl -s ifconfig.me)
echo "Server IP: $server_ip"

# Refresh and get k_param
refresh_output=$(curl -s "http://${server_ip}:8080/refresh")
k_param=$(echo $refresh_output | jq -r '.k')
echo "k_param: $k_param"

# API request details
API_URL="http://account.network3.ai:8080/api/bind_email_node"
EMAIL="baranloufarzad@gmail.com"

# URL encode the parameters
EMAIL_ENCODED=$(printf %s "$EMAIL" | jq -sRr @uri)
K_PARAM_ENCODED=$(printf %s "$k_param" | jq -sRr @uri)
P_PARAM_ENCODED=$(printf %s "$p_param" | jq -sRr @uri)

# Construct the data string with encoded values
DATA="e=$EMAIL_ENCODED&k=$K_PARAM_ENCODED&p=$P_PARAM_ENCODED"

# Send the POST request
response=$(curl -s -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "$DATA" \
  "$API_URL")

# Print the response
echo "Response: $response"
