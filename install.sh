#!/bin/sh
# SCRIPT: install.sh
# PURPOSE: Install the plugin into cPanel
# AUTHOR: Sebastian Oderland

clear
echo "Installing Plugin"

# Create the directory for the plugin
mkdir -p /usr/local/cpanel/base/frontend/paper_lantern/update_primary_domain

# Get the plugin files from Github
curl -s https://raw.githubusercontent.com/SebastianOderland/update_primary_domain/master/plugin_files.tar.gz > /root/plugin_files.tar.gz

# Uncompress the archive
tar xzf plugin_files.tar.gz

# Move files to /usr/local/cpanel/base/frontend/paper_lantern/[plugin_name] directory
mv /root/update_primary_domain.pl /usr/local/cpanel/base/frontend/paper_lantern/update_primary_domain
mv /root/update_primary_domain.tar.gz /usr/local/cpanel/base/frontend/paper_lantern/update_primary_domain

# Install the plugin (which also places the png image in the proper location)
/usr/local/cpanel/scripts/install /usr/local/cpanel/base/frontend/paper_lantern/update_primary_domain/update_primary_domain.tar.gz

echo "Installation is complete!"

