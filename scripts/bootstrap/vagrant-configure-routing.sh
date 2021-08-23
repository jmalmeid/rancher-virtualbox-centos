#!/bin/bash

sudo yum install NetworkManager-config-routing-rules -y
sudo systemctl enable NetworkManager-dispatcher.service
sudo systemctl start NetworkManager-dispatcher.service

INTERNAL_IP=$(ip -4 --oneline addr | grep -v secondary | grep -oP '(10\.240\.0\.[0-9]{1,3})(?=/)')

case "$INTERNAL_IP" in
10.240.0.20)
  sudo ip route add 10.200.1.0/24 via 10.240.0.21
  sudo ip route add 10.200.2.0/24 via 10.240.0.22
  cat <<EOF | sudo tee /etc/sysconfig/network-scripts/route-eth1
10.200.1.0/24 via 10.240.0.21
10.200.2.0/24 via 10.240.0.22
EOF
  ;;
10.240.0.21)
  sudo ip route add 10.200.0.0/24 via 10.240.0.20
  sudo ip route add 10.200.2.0/24 via 10.240.0.22
  cat <<EOF | sudo tee /etc/sysconfig/network-scripts/route-eth1
10.200.0.0/24 via 10.240.0.20
10.200.2.0/24 via 10.240.0.22
EOF
  ;;
10.240.0.22)
  sudo ip route add 10.200.0.0/24 via 10.240.0.20
  sudo ip route add 10.200.1.0/24 via 10.240.0.21
  cat <<EOF | sudo tee /etc/sysconfig/network-scripts/route-eth1
10.200.0.0/24 via 10.240.0.20
10.200.1.0/24 via 10.240.0.21
EOF
  ;;
*)
  sudo ip route add 10.200.0.0/24 via 10.240.0.20
  sudo ip route add 10.200.1.0/24 via 10.240.0.21
  sudo ip route add 10.200.2.0/24 via 10.240.0.22
  cat <<EOF | sudo tee /etc/sysconfig/network-scripts/route-eth1
10.200.0.0/24 via 10.240.0.20
10.200.1.0/24 via 10.240.0.21
10.200.2.0/24 via 10.240.0.22
EOF
  ;;
esac
