# mssql-export-tools
Microsoft SQL Server object exporting tools


## Export-Dacpac

Extract SQL Server databases DACPACs to *.dacpac files.


### Usage

```powershell
PS C:\> Export-Dacpac -Server contoso.com -Folder ~\dacpacs\contoso
```

### Help

```powershell
PS C:\> Get-Help Export-Dacpac -Full
```


## Export-Dtsx

Export SQL Server's SSIS-packages (package model) to \*.dtsx files.


### Usage

```powershell
PS C:\> Export-Dtsx -Server contoso.com -Output ~\dtsx\contoso
```


### Help

```powershell
PS C:\> Get-Help Export-Dtsx -Full
```


## Export-Ispac

Extract SQL Server Integration Service Projects to *.ispac files.


### Usage

```powershell
PS C:\> Export-Ispac -Server contoso.com -Folder ~\dacpacs\contoso 
```

### Help

```powershell
PS C:\> Get-Help Export-Ispac -Full
```

