# Usage

## Export from Portal

Exporting will sync all web files, pages (including CSS and JS), templates,
and content snippets from your Power Platform portal to your local directory.

```powershell
.\sync.ps1 -BasePath .
```

When executing this script, you will be prompted to log into your Dynamics
instance from which you wish to sync your portal(s).

## Importing into Portal

Importing will sync all local web files, pages (including CSS and JS), templates,
and content snippets **with changes** into your Power Platform portal instance.

```powershell
.\sync.ps1 -BasePath . -Import $True
```
