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
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 6443 -j ACCEPT
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 9345 -j ACCEPT
iptables-save > /etc/sysconfig/iptables

# Setup required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-haproxy.conf
net.ipv4.ip_nonlocal_bind = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

sudo yum install wget haproxy -y

sudo yum install net-tools bind-utils telnet tcpdump -y

sudo systemctl enable haproxy

sudo setsebool haproxy_connect_any=1
sudo mkdir /run/haproxy

cat >/etc/haproxy/haproxy.cfg <<EOF
global
	log /dev/log	local0
	log /dev/log	local1 notice
	chroot /var/lib/haproxy
	stats socket /run/haproxy/admin.sock mode 660 level admin
	stats timeout 30s
	user haproxy
	group haproxy
	daemon
	# Default SSL material locations
	ca-base /etc/ssl/certs
	crt-base /etc/ssl/private
	# Default ciphers to use on SSL-enabled listening sockets.
	# For more information, see ciphers(1SSL). This list is from:
	#  https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
	ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS
	ssl-default-bind-options no-sslv3

defaults
	log	global
	mode	tcp
	option	tcplog
	option	dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000

frontend api 
	bind 10.240.0.40:6443
	default_backend api_backend

backend api_backend
	balance roundrobin
	mode tcp
	server controller-0 10.240.0.10:6443 check inter 1000
	server controller-1 10.240.0.11:6443 check inter 1000
	server controller-2 10.240.0.12:6443 check inter 1000

frontend rancher
	bind 10.240.0.40:9345
	default_backend rancher_backend

backend rancher_backend
	balance roundrobin
	mode tcp
	server controller-0 10.240.0.10:9345 check inter 1000
	server controller-1 10.240.0.11:9345 check inter 1000
	server controller-2 10.240.0.12:9345 check inter 1000
EOF

mkdir /run/haproxy

systemctl enable haproxy
systemctl restart haproxy
systemctl status haproxy -l
