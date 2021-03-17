#!/bin/sh

SERVER=$1


ssh ${SERVER} """

echo "Installing [Update Primary Domain] Plugin"

curl -s https://raw.githubusercontent.com/SebastianOderland/update_primary_domain/main/plugin.tar.gz > /root/tmp/plugin.tar.gz;

tar -xvzf /root/tmp/plugin.tar.gz --directory /root/tmp;


mv -v /root/tmp/plugin/* /usr/local/cpanel/base/frontend/paper_lantern/update_primary_domain/
mkdir -p /usr/local/cpanel/base/frontend/paper_lantern/update_primary_domain
/usr/local/cpanel/scripts/install_plugin /usr/local/cpanel/base/frontend/paper_lantern/update_primary_domain/update_primary_domain.tar.gz

rm -rf /root/tmp/plugin.tar.gz
rm -rf /root/tmp/plugin
"""

echo "Installation is complete!"

#rm /usr/local/cpanel/base/frontend/paper_lantern/update_primary_domain/
