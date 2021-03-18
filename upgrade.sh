#!/bin/sh

echo "Installing [Update Primary Domain] Plugin"

# Get the plugin files from Github
curl -s https://raw.githubusercontent.com/SebastianOderland/update_primary_domain/main/plugin.tar.gz > /root/plugin.tar.gz

# Uncompress the archive
tar xzf plugin.tar.gz

# Create the directory for the plugin
mkdir -p /usr/local/cpanel/base/frontend/paper_lantern/update_primary_domain

# Move files to /usr/local/cpanel/base/frontend/paper_lantern/[plugin_name] directory
mv /root/update_primary_domain.pl /usr/local/cpanel/base/frontend/paper_lantern/update_primary_domain
mv /root/update_primary_domain.tar.gz /usr/local/cpanel/base/frontend/paper_lantern/update_primary_domain

# Install the plugin (which also places the png image in the proper location)
/usr/local/cpanel/scripts/install /usr/local/cpanel/base/frontend/paper_lantern/update_primary_domain/update_primary_domain.tar.gz

echo "Installation is complete!"