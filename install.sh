#!/bin/sh

SERVER=$1

ssh ${SERVER} """

echo "Installing [Change Primary Domain] Plugin"

curl -s -H 'Cache-Control: no-cache' https://raw.githubusercontent.com/SebastianOderland/update_primary_domain/main/plugin.tar.gz > /root/tmp/plugin_files.tar.gz;

tar -xvzf /root/tmp/plugin_files.tar.gz --directory /root/tmp;

/usr/local/cpanel/scripts/install_plugin /root/tmp/plugin_files/primary_domain.tar.gz
mkdir -p /usr/local/cpanel/base/frontend/paper_lantern/primary_domain
mv -v /root/tmp/plugin_files/* /usr/local/cpanel/base/frontend/paper_lantern/primary_domain/


"""

echo "Installation is complete!"

#/usr/local/cpanel/scripts/install_plugin /usr/local/cpanel/base/frontend/paper_lantern/change_primary_domain/change_primary_domain.tar.gz
#rm -rf /root/tmp/plugin
#rm -rf /root/tmp/plugin.tar.gz
#rm /usr/local/cpanel/base/frontend/paper_lantern/update_primary_domain/

#Slash_And_Or_Dashes99