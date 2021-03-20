#!/bin/sh


# Get the plugin files from Github
curl -s https://raw.githubusercontent.com/SebastianOderland/update_primary_domain/main/plugin.tar.gz > /root/change_primary_domain.tar.gz

# Uncompress the archive
tar xzf change_primary_domain.tar.gz

# Create the directory for the plugin
mkdir -p /usr/local/cpanel/base/frontend/paper_lantern/change_primary_domain

# Move files to /usr/local/cpanel/base/frontend/paper_lantern/[plugin_name] directory
mv /root/change_primary_domain.pl /usr/local/cpanel/base/frontend/paper_lantern/change_primary_domain
mv /root/change_primary_domain.tar.gz /usr/local/cpanel/base/frontend/paper_lantern/change_primary_domain

# Install the plugin (which also places the png image in the proper location)
/usr/local/cpanel/scripts/install /usr/local/cpanel/base/frontend/paper_lantern/change_primary_domain/change_primary_domain.tar.gz

echo "Installation is complete!"