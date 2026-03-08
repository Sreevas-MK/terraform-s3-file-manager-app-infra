#!/bin/bash

# Wait for network to be ready
sleep 30

# Variables
APP_DIR="/var/s3-nodejs-app"
SERVICE_NAME="s3-nodejs-app"
SERVICE_FILE="/etc/systemd/system/$${SERVICE_NAME}.service"
ENV_FILE="/etc/app.env"
APP_USER="ec2-user"

# Step 1: Update the system and install git & Cloudwatch agent
echo "Updating system"
dnf update -y

# Install CodeDeploy Agent
echo "Installing AWS CodeDeploy Agent..."

dnf install -y ruby wget

cd /tmp
wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install

chmod +x ./install
./install auto

# Start and enable CodeDeploy agent
systemctl start codedeploy-agent
systemctl enable codedeploy-agent

# Verify installation
systemctl status codedeploy-agent --no-pager


# Install CloudWatch Agent 

dnf install amazon-cloudwatch-agent -y

# Install CloudWatch Agent In setup.sh

sudo tee /opt/aws/amazon-cloudwatch-agent/bin/config.json <<EOF
{
  "metrics": {
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    },
    "append_dimensions": {
      "AutoScalingGroupName": "$${aws:AutoScalingGroupName}"
    }
  },

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

# Start Cloudwatch agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
-s

# Create a global environment file that persists across reboots
cat <<EOF | sudo tee /etc/app.env
AWS_REGION=${aws_region}
S3_BUCKET_NAME=${app_bucket_name}
EOF

# Make it readable by ec2-user
sudo chmod 644 /etc/app.env

# Install Node.js on Amazon Linux 2023
echo "Installing Node.js..."
# AL2023 has Node.js in its default repositories
dnf install -y nodejs

# Verify Node.js installation
echo "Node version: $(node --version)"
echo "NPM version: $(npm --version)"

# Step 4: Create the application directory
echo "Creating application directory..."
mkdir -p $APP_DIR

# Set proper ownership
chown -R ec2-user:ec2-user $APP_DIR

# Load variables from the file Terraform created
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "Error: $ENV_FILE not found. Infrastructure setup may be incomplete."
    exit 1
fi

# Create the service file

cat > $SERVICE_FILE <<EOF
[Unit]
Description=Node.js S3 App
After=network.target

[Service]
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node $APP_DIR/app.js
Restart=always

Environment=NODE_ENV=production
Environment=AWS_REGION=$AWS_REGION
Environment=S3_BUCKET_NAME=$S3_BUCKET_NAME

StandardOutput=append:/var/log/s3-nodejs-app.log
StandardError=append:/var/log/s3-nodejs-app.log

[Install]
WantedBy=multi-user.target
EOF

# Reload and Restart
systemctl daemon-reload
systemctl enable $SERVICE_NAME

echo "Setup complete!"

