#!/bin/bash
# User data script for Syslog server initialization

# Update system
yum update -y

# Install rsyslog and CloudWatch agent
yum install -y rsyslog amazon-cloudwatch-agent

# Configure rsyslog for centralized logging
cat > /etc/rsyslog.conf << 'EOF'
# /etc/rsyslog.conf configuration for centralized syslog server

# Modules
module(load="imuxsock") # provides support for local system logging
module(load="imklog")   # provides kernel logging support
module(load="immark")   # provides --MARK-- message capability
module(load="imudp")    # provides UDP syslog reception
module(load="imtcp")    # provides TCP syslog reception

# Enable UDP and TCP reception
input(type="imudp" port="514")
input(type="imtcp" port="514")

# Global directives
$WorkDirectory /var/lib/rsyslog
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
$RepeatedMsgReduction on
$FileOwner syslog
$FileGroup adm
$FileCreateMode 0640
$DirCreateMode 0755
$Umask 0022
$PrivDropToUser syslog
$PrivDropToGroup syslog

# Rules
*.*;auth,authpriv.none          /var/log/syslog
auth,authpriv.*                 /var/log/auth.log
*.*;auth,authpriv.none          -/var/log/messages
daemon.*                        -/var/log/daemon.log
kern.*                          -/var/log/kern.log
lpr.*                           -/var/log/lpr.log
mail.*                          -/var/log/mail.log
user.*                          -/var/log/user.log

# Emergency messages to all users
*.emerg                         :omusrmsg:*

# Remote host templates (by hostname)
$template RemoteHost,"/var/log/remote/%HOSTNAME%/%programname%.log"
*.* ?RemoteHost
& stop

EOF

# Configure log rotation
cat > /etc/logrotate.d/rsyslog << 'EOF'
/var/log/syslog
/var/log/auth.log
/var/log/messages
/var/log/daemon.log
/var/log/kern.log
/var/log/lpr.log
/var/log/mail.log
/var/log/user.log
/var/log/remote/*/*
{
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 640 syslog adm
    postrotate
        systemctl reload rsyslog
    endscript
}
EOF

# Create remote log directory
mkdir -p /var/log/remote
chown syslog:adm /var/log/remote

# Configure CloudWatch agent for log forwarding to Splunk
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/syslog",
                        "log_group_name": "${environment}-syslog",
                        "log_stream_name": "syslog-${instance_index}"
                    },
                    {
                        "file_path": "/var/log/auth.log",
                        "log_group_name": "${environment}-auth",
                        "log_stream_name": "auth-${instance_index}"
                    },
                    {
                        "file_path": "/var/log/remote/*/*",
                        "log_group_name": "${environment}-remote-logs",
                        "log_stream_name": "remote-${instance_index}"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "${environment}/Syslog",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start and enable services
systemctl enable rsyslog
systemctl start rsyslog
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Configure firewall
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-port=514/tcp
firewall-cmd --permanent --add-port=514/udp
firewall-cmd --reload

%{ if length(splunk_indexer_ips) > 0 }
# Configure log forwarding to Splunk (if indexers are available)
cat > /etc/rsyslog.d/50-splunk-forward.conf << 'EOF'
# Forward logs to Splunk indexers
%{ for ip in splunk_indexer_ips }
*.* @@${ip}:9997
%{ endfor }
EOF

systemctl restart rsyslog
%{ endif }

echo "Syslog server ${instance_index} initialization completed" > /var/log/syslog-init.log
