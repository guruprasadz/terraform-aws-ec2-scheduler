#!/bin/bash
set -e

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Starting EC2 initialization at $(date) ==="

# Update system packages
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install essential tools
echo "Installing essential tools..."
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    net-tools \
    awscli \
    python3-pip \
    python3-venv \
    build-essential \
    libssl-dev \
    libffi-dev

# Install Node.js (for frontend development)
echo "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install Python ML libraries for volatility analysis
echo "Installing Python packages..."
pip3 install --upgrade pip setuptools wheel
pip3 install \
    numpy \
    pandas \
    scipy \
    scikit-learn \
    tensorflow \
    arch \
    statsmodels

# Create application directory
APP_DIR="/home/ubuntu/stock-volatility-analyzer"
mkdir -p $APP_DIR
chown -R ubuntu:ubuntu $APP_DIR

# Configure AWS CLI
echo "Configuring AWS CLI..."
mkdir -p /home/ubuntu/.aws
chown -R ubuntu:ubuntu /home/ubuntu/.aws

# Install Docker (optional, for containerized applications)
# echo "Installing Docker..."
# curl -fsSL https://get.docker.com -o get-docker.sh
# sh get-docker.sh
# usermod -aG docker ubuntu

# Setup CloudWatch agent (optional)
# echo "Installing CloudWatch agent..."
# wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
# dpkg -i -E ./amazon-cloudwatch-agent.deb

# Set timezone to IST
echo "Setting timezone..."
timedatectl set-timezone Asia/Kolkata

# Create a startup status file
echo "$(date)" > /home/ubuntu/startup-complete.txt
chown ubuntu:ubuntu /home/ubuntu/startup-complete.txt

# Security: Set up automatic security updates
echo "Configuring automatic security updates..."
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# Log completion
echo "=== EC2 initialization completed at $(date) ==="
