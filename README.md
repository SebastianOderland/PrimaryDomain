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

- Probably redo the process of adding/deleting/editing DNS-Records(Don't use the cPanel/WHM API).
- The process takes quite a while, so a loading bar/screen is kinda necessary(If we are still using cPanel/WHM API that is).
- Store a backup of the data, in case it fails.
- Update primary domain in WHMCS.

&nbsp;
&nbsp;

## Order of Execution

1. Get the current Subdomains and DNS Zones
2. Delete current Addon Domain
3. Change Primary Domain
4. Create new Addon Domain
5. Get the new Subdomains and DNS Zones
6. Import old DNS Records into new DNS Zones
