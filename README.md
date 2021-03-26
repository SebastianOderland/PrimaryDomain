## TODO

- DNS Zone: New Primary Domain / Current Addon Domain
1. Remove all the DNS-records in virtual_host, that does not contain a subdomain.
2. Paste all the DNS-records saved from before to virtual_host.
3. Increase Serial Number.
4. SPF-records keeps getting added when changing primary domain.
   
5. Maybe readd the subdomains again, so it's not above the other records.

- DNS Zone: New Addon Domain / Current Primary Domain
1. Remove all DNS Records in old dns zone list that contains a subdomain.
2. Remove all DNS Records from the current dns zone.
3. Add all DNS Records from old dns zone list.
   
- Fix E-mailaccounts.
- Subdomains?
- Update primary domain in WHMCS
- Allow creation of new Primary Domain, or just changing the Primary Domain?