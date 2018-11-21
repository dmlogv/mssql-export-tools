<#
.SYNOPSIS
    Extract SQL Server databases DACPACs to *.dacpac files.


.DESCRIPTION
    The Extract-Dacpac function uses SqlPackage.exe tool 
    for a batch extraction of data-tier application to the file system.

    You may need extract a database's DACPAC for the importing
    into SQL Server Data Tools Project.

    SqlPackage uses Integrated Security (bypass Active Directory authorization)
    to authenticate user at SQL Server.


.PARAMETER Server
    Microsoft SQL Server instance name. 

.PARAMETER Folder
    Output folder for placing extracted DACPACs.
    

.EXAMPLE
    Export-Dacpac -Server contoso.com -Folder ~\dacpacs\contoso 


.NOTES
    Need installed DAC Framework (see https://docs.microsoft.com/ru-ru/sql/tools/sqlpackage-download)
#>


Param (
    [Parameter(Mandatory = $true)]
    [string] $Server,
    [Parameter(Mandatory = $true)]
    [string] $Folder
)


# SqlPackage.exe location
$sqlpackage = "${Env:ProgramFiles(x86)}\Microsoft SQL Server\140\DAC\bin\SqlPackage.exe"


# Create output folder
If (-Not (Test-Path $folder)) {
    New-Item -ItemType Directory "$folder" > $null
}


# Get DB list, exclude system DBs and started with '_'
$query = "set nocount on 
    select name 
    from sys.databases 
    where 
        name not in ('master', 'model', 'msdb', 'tempdb') 
        and name not like '\_%' escape '\'
    "


sqlcmd -S $Server -Q $query -h -1 | ForEach {
    $db = $_.Trim()
    $fullname = Join-Path $Folder "$db.dacpac"

    Write-Host $db "=>" $fullname

    & "$sqlpackage" /Action:Extract /SourceDatabaseName:"$db" /SourceServerName:"$server" /TargetFile:"$fullname" /p:IgnorePermissions=False
}