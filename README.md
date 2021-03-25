## Order of Execution

1. Get the current Subdomains and DNS Zones
2. Delete current Addon Domain
3. Change Primary Domain
4. Create new Addon Domain
5. Get the new Subdomains and DNS Zones
6. Import old DNS Records into new DNS Zones

## Notes

- E-Mail<br>
E-mailaccounts does not seem to update after changing primary domain.
So it seems to be working for now.
"Seems" to be done.

- DNS<br>
Almost done.

- Documentroot<br>
Done!

## TODO

- The Addon Domain needs to have public_html as document root before changing it to Primary Domain.
- Allow current addon domain to have subdomains
- Probably redo the process of importing DNS-Records
  
- Either check all the "potential" outcome before executing anything, or store a backup of the data
- Update primary domain in WHMCS