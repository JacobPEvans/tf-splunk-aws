#!/bin/bash
# User data script for Splunk Indexer initialization

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

%{ if enable_clustering && indexer_count >= 3 }
# Configure clustering (if enabled and sufficient indexers)
sudo -u splunk /opt/splunk/bin/splunk edit cluster-config -mode peer -master_uri https://cluster-master:8089 -replication_factor 2 -search_factor 2 -secret cluster_secret -auth admin:${splunk_password}
%{ endif }

# Configure as indexer
sudo -u splunk /opt/splunk/bin/splunk set servername "${environment}-indexer-${instance_index + 1}" -auth admin:${splunk_password}

# Configure data retention and indexing
sudo -u splunk /opt/splunk/bin/splunk add index main_idx -auth admin:${splunk_password}

# Restart Splunk to apply configurations
sudo -u splunk /opt/splunk/bin/splunk restart

# Configure firewall
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-port=8000/tcp
firewall-cmd --permanent --add-port=8089/tcp
firewall-cmd --permanent --add-port=9997/tcp
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload

echo "Splunk Indexer ${instance_index + 1} initialization completed" > /var/log/splunk-init.log
