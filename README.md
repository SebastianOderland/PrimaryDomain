## Notes

- Documentroot\
Done.

- Subdomains\
Done.

- DNS\
Done for now.

- E-Mail\
Done?

&nbsp;
&nbsp;

## Todo

- Probably redo the process of adding/deleting/editing DNS-Records( Don't use the cPanel/WHM API ).
- The process takes quite a while, so a loading bar/screen is kinda necessary( If we are still using cPanel/WHM API that is ).
- Store a backup of the data, in case it fails.
- Update primary domain in WHMCS.

&nbsp;
&nbsp;

## Order of Execution

0. Check the 2 domains
1. Get the current Subdomains and DNS Zones
2. Delete all subdomains on current Addon Domain
3. Delete current Addon Domain
4. Change Primary Domain
5. Create new Addon Domain
6. Get the new Subdomains and DNS Zones
7. Delete the automatically created subdomains
8. Import old DNS Records into new DNS Zones
9. Recreate the old subdomains