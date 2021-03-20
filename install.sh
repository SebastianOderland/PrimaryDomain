#!/bin/sh

SERVER=$1

ssh ${SERVER} """

echo "Installing [Change Primary Domain] Plugin"

curl -s https://raw.githubusercontent.com/SebastianOderland/update_primary_domain/main/plugin.tar.gz > /root/tmp/change_primary_domain.tar.gz;

tar -xvzf /root/tmp/change_primary_domain.tar.gz --directory /root/tmp;


mv -v /root/tmp/change_primary_domain/* /usr/local/cpanel/base/frontend/paper_lantern/change_primary_domain/
mkdir -p /usr/local/cpanel/base/frontend/paper_lantern/change_primary_domain
/usr/local/cpanel/scripts/install_plugin /usr/local/cpanel/base/frontend/paper_lantern/change_primary_domain/change_primary_domain.tar.gz

"""

echo "Installation is complete!"

#rm -rf /root/tmp/plugin
#rm -rf /root/tmp/plugin.tar.gz
#rm /usr/local/cpanel/base/frontend/paper_lantern/update_primary_domain/
