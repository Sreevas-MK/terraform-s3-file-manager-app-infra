#!/bin/bash

# Wait for network to be ready
sleep 30

# Variables
APP_DIR="/var/s3-nodejs-app"
SERVICE_NAME="s3-nodejs-app"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
TEMP_DIR="/tmp/s3-node-app"

# Step 1: Update the system and install git & Cloudwatch agent
echo "Updating system and installing git..."
dnf update -y
dnf install -y git


# Install CloudWatch Agent In setup.sh

dnf install amazon-cloudwatch-agent -y

# Install CloudWatch Agent In setup.sh

sudo tee /opt/aws/amazon-cloudwatch-agent/bin/config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/s3-node-app/ec2",
            "log_stream_name": "{instance_id}"
          },

          {
            "file_path": "/var/log/s3-nodejs-app.log",
            "log_group_name": "/s3-node-app/application",
            "log_stream_name": "{instance_id}"
          },

          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_name": "/s3-node-app/ec2",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Step 2: Install Node.js on Amazon Linux 2023
echo "Installing Node.js..."
# AL2023 has Node.js in its default repositories
dnf install -y nodejs

# Verify Node.js installation
echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"

# Step 3: Create a temporary directory and clone the repository
echo "Cloning the repository..."
rm -rf $TEMP_DIR
git clone https://github.com/Sreevas-MK/s3node-app-with-versioning.git $TEMP_DIR

# Step 4: Create the application directory
echo "Creating application directory..."
mkdir -p $APP_DIR

# Step 5: Copy app files to the application directory
echo "Copying app files to $APP_DIR..."
cp -r $TEMP_DIR/. $APP_DIR/

# Set proper ownership
chown -R ec2-user:ec2-user $APP_DIR

# Verify package.json exists
if [ ! -f "$APP_DIR/package.json" ]; then
    echo "Error: package.json is missing in $APP_DIR"
    ls -la $APP_DIR
    exit 1
fi

# Step 6: Install Node.js dependencies
echo "Installing Node.js dependencies..."
cd $APP_DIR
# Run npm install as ec2-user
sudo -u ec2-user npm install

# Step 7: Create the systemd service file
echo "Creating systemd service file..."
cat > $SERVICE_FILE <<EOF
[Unit]
Description=Node.js S3 App
After=network.target

[Service]
User=ec2-user
Group=ec2-user
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node $APP_DIR/app.js
Restart=always
Environment=NODE_ENV=production

StandardOutput=append:/var/log/s3-nodejs-app.log
StandardError=append:/var/log/s3-nodejs-app.log

[Install]
WantedBy=multi-user.target
EOF

# Step 8: Reload systemd and enable the service
echo "Reloading systemd and enabling the service..."
systemctl daemon-reload
systemctl start $SERVICE_NAME
systemctl enable $SERVICE_NAME

# Step 9: Check the status of the service
echo "Checking the status of the service..."
sleep 5
systemctl status $SERVICE_NAME --no-pager

# Start Cloudwatch agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
-s

# Clean up
rm -rf $TEMP_DIR

echo "Setup complete! Your Node.js app should now be running."
