#!/bin/bash
# User data script for Splunk Search Head initialization

# Update system
yum update -y

# Install required packages
yum install -y wget curl

# Create splunk user
useradd -m -s /bin/bash splunk

# Download and install Splunk
cd /opt
wget -O splunk-9.1.0-64e843ea36b1-Linux-x86_64.tgz "https://download.splunk.com/products/splunk/releases/9.1.0/linux/splunk-9.1.0-64e843ea36b1-Linux-x86_64.tgz"
tar -xzf splunk-9.1.0-64e843ea36b1-Linux-x86_64.tgz
chown -R splunk:splunk /opt/splunk

# Set up Splunk environment
sudo -u splunk /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd "${splunk_password}"

# Enable boot start
/opt/splunk/bin/splunk enable boot-start -user splunk

# Configure as search head
sudo -u splunk /opt/splunk/bin/splunk set servername "${environment}-search-head" -auth admin:${splunk_password}

# Add indexers as search peers
%{ for indexer_ip in indexer_ips }
sudo -u splunk /opt/splunk/bin/splunk add search-server https://${indexer_ip}:8089 -auth admin:${splunk_password} -remoteUsername admin -remotePassword ${splunk_password}
%{ endfor }

%{ if enable_clustering }
# Configure search head clustering (if enabled)
sudo -u splunk /opt/splunk/bin/splunk edit cluster-config -mode searchhead -master_uri https://cluster-master:8089 -secret cluster_secret -auth admin:${splunk_password}
%{ endif }

# Configure web interface
sudo -u splunk /opt/splunk/bin/splunk set web-port 8000 -auth admin:${splunk_password}

# Restart Splunk to apply configurations
sudo -u splunk /opt/splunk/bin/splunk restart

# Configure firewall
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-port=8000/tcp
firewall-cmd --permanent --add-port=8089/tcp
firewall-cmd --reload

echo "Splunk Search Head initialization completed" > /var/log/splunk-init.log
