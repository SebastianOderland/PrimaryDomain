## Notes

- Documentroot\
Done!

- DNS\
Maybe done?

- Subdomains\
Incomplete.

- E-Mail\
~~E-mailaccounts does not seem to update after changing primary domain.~~\
Nevermind, it updates sometimes.

&nbsp;
&nbsp;

## Todo

- DONE! Remove all subdomains for current Addon Domain
- Remove all DNS-records for subdomains
- Recreate the subdomains
  
- Convert as much as possible to UAPI
- The process takes quite a while, so a loading screen is kinda necessary
- Probably redo the process of importing DNS-Records
- Either check all the "potential" outcome before executing anything, or store a backup of the data
- Update primary domain in WHMCS

&nbsp;
&nbsp;

## Order of Execution

1. Get the current Subdomains and DNS Zones
2. Delete current Addon Domain
3. Change Primary Domain
4. Create new Addon Domain
5. Get the new Subdomains and DNS Zones
6. Import old DNS Records into new DNS Zones
