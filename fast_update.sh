#!/bin/sh
#!/usr/bin/expect -f

tar -czvf plugin/plugin.tar.gz change_primary_domain

rsync -avz -e 'ssh' plugin/* root@cpanel-dev-cl7.oderland.com:/usr/local/cpanel/base/frontend/paper_lantern/change_primary_domain/
rsync -avz -e 'ssh' uapi/* root@cpanel-dev-cl7.oderland.com:/usr/local/cpanel/Cpanel/API/
rsync -avz -e 'ssh' admin/* root@cpanel-dev-cl7.oderland.com:/var/cpanel/perl/Cpanel/Admin/Modules/ChangePrimaryDomain/