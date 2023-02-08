#!/bin/bash
set -e

/usr/bin/apt-get clean

rm -r /etc/netplan/50-cloud-init.yaml /etc/ssh/ssh_host* /etc/sudoers.d/90-cloud-init-users

/usr/bin/truncate --size -0 /etc/machine-id

/usr/bin/gawk -i inplace '/PasswordAuthentication/ { gsub(/yes/, "no") }; { print }' /etc/ssh/sshd_config

rm -r /root/.ssh

rm -r /snap/README

find /usr/share/netplan -name __pycache__ -exec rm -r {} +

rm -r /var/cache/pollinate/seeded /var/cache/snapd/* /var/cache/motd-news

rm -r /var/lib/cloud /var/lib/dbus/machine-id /var/lib/private /var/lib/systemd/timers /var/lib/systemd/timesync /var/lib/systemd/random-seed

rm -r /var/lib/ubuntu-release-upgrader/release-upgrade-available

rm -r /var/lib/update-notifier/fsck-at-reboot

find /var/log -type f -exec rm {} +

rm -r /tmp/* /tmp/.*-unix /var/tmp/*

for i in group gshadow passwd shadow subuid subgid; do
  mv /etc/$i- /etc/$i
done

cd /

rm -r /home/packer

/bin/sync

/sbin/fstrim -v /
