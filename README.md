## Order of Execution

1. Get the current Subdomains and DNS Zones
2. Delete current Addon Domain
3. Change Primary Domain
4. Create new Addon Domain
5. Get the new Subdomains and DNS Zones
6. Import old DNS Records into new DNS Zones

## Notes

- E-Mail<br>
E-mailaccounts does not seem to update after changing primary domain.<br>
So it "seems" to be done.

- Subdomains<br>
Incomplete.

- DNS<br>
Maybe done?

- Documentroot<br>
Done!

## TODO

- Allow current addon domain to have subdomains
- Probably redo the process of importing DNS-Records
  
- Either check all the "potential" outcome before executing anything, or store a backup of the data
- Update primary domain in WHMCS