#!/bin/bash

set -euo pipefail

mkdir -p /usr/local/bin
cat <<EOF | sudo tee -a /etc/profile
export PATH=$PATH:/usr/local/bin
EOF

cat <<EOF | sudo tee -a /etc/hosts
#Vagrant machines
10.240.0.10 rke-master-0
10.240.0.11 rke-master-1
10.240.0.12 rke-master-2
10.240.0.20 rke-worker-0
10.240.0.21 rke-worker-1
10.240.0.22 rke-worker-2
EOF

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

cat <<EOF | sudo tee /etc/sysctl.d/50-default.conf
net.ipv4.conf.all.rp_filter         = 2
net.ipv4.conf.default.rp_filter     = 2
EOF

# Apply sysctl params without reboot
sudo sysctl --system

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo rm -f /swapfile1

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

#For Routing
yum install NetworkManager-config-routing-rules -y
systemctl enable NetworkManager-dispatcher.service
systemctl start NetworkManager-dispatcher.service
 
#iptables rules
iptables -I INPUT -p igmp -j ACCEPT
iptables -I INPUT -m addrtype --dst-type MULTICAST -j ACCEPT
iptables -I INPUT -m state --state NEW -p tcp -m multiport --dports 30000:32767 -j ACCEPT
iptables -I INPUT -m state --state NEW -p udp -m multiport --dports 30000:32767 -j ACCEPT
iptables -I INPUT -m state --state NEW -p tcp -m multiport --dports 2379:2380 -j ACCEPT
iptables -I INPUT -m state --state NEW -p tcp -m multiport --dports 10250:10255 -j ACCEPT
iptables -I INPUT -p udp -m state --state NEW -m udp --dport 53 -j ACCEPT
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 53 -j ACCEPT
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 9345 -j ACCEPT
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 8472 -j ACCEPT
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 6443 -j ACCEPT
iptables -I INPUT -p udp -m state --state NEW -m udp --dport 4789 -j ACCEPT
iptables-save > /etc/sysconfig/iptables

cat << EOF > /etc/yum.repos.d/rancher-rke2-1-18-latest.repo
[rancher-rke2-common-latest]
name=Rancher RKE2 Common Latest
baseurl=https://rpm.rancher.io/rke2/latest/common/centos/7/noarch
enabled=1
gpgcheck=1
gpgkey=https://rpm.rancher.io/public.key

[rancher-rke2-1-18-latest]
name=Rancher RKE2 1.18 Latest
baseurl=https://rpm.rancher.io/rke2/latest/1.18/centos/7/x86_64
enabled=1
gpgcheck=1
gpgkey=https://rpm.rancher.io/public.key
EOF

yum repolist

yum install rke2-agent -y

cat << EOF | tee /etc/rancher/rke2/config.yaml
server: https://rke-master-0:9345
token: AEuClPrkeCMnQlqKp82c8rLPcG+ay03i
EOF

#systemctl enable rke2-agent
#systemctl start rke2-agent
