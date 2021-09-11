#!/bin/bash

set -euo pipefail

mkdir -p /usr/local/bin
cat <<EOF | sudo tee -a /etc/profile
export PATH=$PATH:/usr/local/bin
EOF

#To Permissive
setenforce Permissive
sed -i "s/SELINUX=enforcing/SELINUX=permissive/g" /etc/selinux/config

yum -y install epel-release
yum -y remove firewalld
yum install -y iptables-services wget
systemctl enable iptables
systemctl start iptables

#Install support tools
yum install -y net-tools bind-utils telnet tcpdump
 
#iptables rules
iptables -I INPUT -p igmp -j ACCEPT
iptables -I INPUT -m addrtype --dst-type MULTICAST -j ACCEPT
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
iptables-save > /etc/sysconfig/iptables

# Apply sysctl params without reboot
sudo sysctl --system

cat <<EOF | sudo tee -a /etc/hosts
#Vagrant machines
10.240.0.40 rke-lb-0
10.240.0.10 rke-master-0
10.240.0.11 rke-master-1
10.240.0.12 rke-master-2
10.240.0.20 rke-worker-0
10.240.0.21 rke-worker-1
10.240.0.22 rke-worker-2
EOF
