#!/bin/sh

set -e

pre_exec=""

$pre_exec cat > /usr/local/bin/createuser.sh <<EOF
#!/bin/bash
set +x
useradd \$1
if [ \$? -gt 0 ];then
    echo "user \$1 already exist"
    exit 1
fi
usermod -g root \$1
sed -i "/^root.*/a\\\\\$1  ALL=(ALL)       ALL" /etc/sudoers
EOF

$pre_exec chmod 0755 /usr/local/bin/createuser.sh

teleport_version="v9.1.2"
teleport_domain=${TELEPORT_DOMAIN-""}
teleport_token=${TELEPORT_TOKEN-""}
ec2_owner=${EC2_OWNER-""}
ec2_users=${EC2_USERS-""}

$pre_exec /usr/local/bin/createuser.sh $ec2_owner

teleport_installed_version=$(tctl version | awk '{print $2}')

if [ "$(tctl version | awk '{print $2}')" != "$teleport_version" ]; then
  echo "Teleport version unmatched, will install version $teleport_version."
  curl https://get.gravitational.com/teleport-$teleport_version-linux-arm64-bin.tar.gz.sha256
  curl -O https://get.gravitational.com/teleport-$teleport_version-linux-arm64-bin.tar.gz
  tar -xzf teleport-$teleport_version-linux-arm64-bin.tar.gz
  cd teleport
  $pre_exec ./install

  cd ..
  rm -fr teleport-$teleport_version-linux-arm64-bin.tar.gz
fi

$pre_exec cat >/etc/default/teleport-node <<EOF
OWNER=$ec2_owner
USERS=$ec2_users
EOF

$pre_exec cat >/etc/systemd/system/teleport-node.service <<EOF
[Unit]
Description=Teleport Node Service
After=network.target

[Service]
Type=simple
Restart=on-failure
EnvironmentFile=-/etc/default/teleport-node
ExecStart=/usr/local/bin/teleport start --roles=node --token=$teleport_token --auth-server=$teleport_domain:443 --labels=owner=$ec2_owner,users=$ec2_users
ExecReload=/bin/kill -HUP \$MAINPID
PIDFile=/run/teleport-node.pid
LimitNOFILE=8192

[Install]
WantedBy=multi-user.target
EOF

$pre_exec systemctl daemon-reload
$pre_exec systemctl enable teleport-node
$pre_exec systemctl restart teleport-node