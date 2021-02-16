# Usage

## Export from Portal

Exporting will sync all web files, pages (including CSS and JS), templates,
and content snippets from your Power Platform portal to your local directory.

```powershell
.\sync.ps1 -BasePath .
```

When executing this script, you will be prompted to log into your Dynamics
instance from which you wish to sync your portal(s).

**NOTE:** if you wish to automate the script in some way, you may pass in
a [connection string](https://docs.microsoft.com/en-us/powerapps/developer/data-platform/xrm-tooling/use-connection-strings-xrm-tooling-connect) to authenticate to your CRM
instead of using the default interactive prompt:

```powershell
.\sync.ps1 -BasePath . -ConnectionString "AuthType=ClientString;url=https://contosotest.crm.dynamics.com;ClientId={AppId};ClientSecret={ClientSecret}"
```

## Importing into Portal

Importing will sync all local web files, pages (including CSS and JS), templates,
and content snippets **with changes** into your Power Platform portal instance.

```powershell
.\sync.ps1 -BasePath . -Import $True
```
