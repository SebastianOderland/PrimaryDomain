## Notes

- Documentroot\
Done!

- Subdomains\
Done!

- DNS\
Done for now!

- E-Mail\
~~E-mailaccounts does not seem to update after changing primary domain~~\
Nevermind it updates sometimes, but can't seem to replicate it.

&nbsp;
&nbsp;

## Todo

- Convert as much as possible to UAPI.
- The process takes quite a while, so a loading bar/screen is kinda necessary.
- Probably redo the process of importing DNS-Records(Don't use the cPanel/WHM API).
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
