#!/bin/bash
# User data script for Universal Forwarder initialization

# Update system
yum update -y

# Install required packages
yum install -y wget curl

# Create splunk user
useradd -m -s /bin/bash splunk

# Download and install Universal Forwarder
cd /opt
wget -O splunkforwarder-9.1.0-64e843ea36b1-Linux-x86_64.tgz "https://download.splunk.com/products/universalforwarder/releases/9.1.0/linux/splunkforwarder-9.1.0-64e843ea36b1-Linux-x86_64.tgz"
tar -xzf splunkforwarder-9.1.0-64e843ea36b1-Linux-x86_64.tgz
chown -R splunk:splunk /opt/splunkforwarder

# Set up Splunk Forwarder environment
sudo -u splunk /opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd "${splunk_password}"

# Enable boot start
/opt/splunkforwarder/bin/splunk enable boot-start -user splunk

# Configure forwarding to indexers
%{ for indexer_ip in indexer_ips }
sudo -u splunk /opt/splunkforwarder/bin/splunk add forward-server ${indexer_ip}:9997 -auth admin:${splunk_password}
%{ endfor }

# Configure data inputs (basic system logs)
sudo -u splunk /opt/splunkforwarder/bin/splunk add monitor /var/log -auth admin:${splunk_password}

# Set deployment server (if needed)
# sudo -u splunk /opt/splunkforwarder/bin/splunk set deploy-poll deployment-server:8089 -auth admin:${splunk_password}

# Restart forwarder to apply configurations
sudo -u splunk /opt/splunkforwarder/bin/splunk restart

echo "Universal Forwarder initialization completed" > /var/log/splunk-forwarder-init.log
