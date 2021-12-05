#!/bin/bash
systemctl daemon-reload
systemctl enable xmrig
systemctl enable setcpugov

chown -R arch /home/arch
sudo -i -u arch fish << EOF
cd /home/arch
git clone https://github.com/MoneroOcean/xmrig
xmrig_build
EOF