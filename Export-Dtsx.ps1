<#
.SYNOPSIS
    Export SQL Server's SSIS-packages (package model) to *.dtsx files.


.DESCRIPTION
    The Export-Dtsx function exports SQL Server Integration Service packages
    stored in msdb database of SQL Server instance (package deployment model) 
    to the file system as *.dtsx files.

    Each file will be encrypted with a password (see Key parameter).


.PARAMETER Server
    Microsoft SQL Server instance name

.PARAMETER Output
    Output folder for placing extracted *.dtsx

.PARAMETER Key
    Password for an DTSX encryption
    

.EXAMPLE
    Export-Dtsx -Server contoso.com -Output ~\dtsx\contoso 


.NOTES
    Need installed dtutil tool (see https://docs.microsoft.com/ru-ru/sql/integration-services/dtutil-utility) 
    in the PATH environment variable (included in the SQL Server Integration Services installation).
#>


Param (
    [Parameter(Mandatory = $true)]
    [string] $Server,
    [Parameter(Mandatory = $true)]
    [string] $Output,
    [string] $Key      = 'F,shdfku'
)

$ErrorActionPreference = "Stop"


# Get MSDB SSIS list
$ssis_packages = Invoke-Sqlcmd -ServerInstance $Server -Query @"
    WITH cte AS (
        SELECT
            CAST(foldername AS VARCHAR(8000)) AS folderpath
            , folderid                         
        FROM msdb..sysssispackagefolders
        WHERE parentfolderid = '00000000-0000-0000-0000-000000000000'

        UNION ALL

        SELECT
	        CAST(foldername AS VARCHAR(8000)) AS folderpath
            , folderid                         
        FROM msdb..sysssispackagefolders
        WHERE parentfolderid IS NULL

        UNION ALL

        SELECT
            CAST(c.folderpath + '\' + f.foldername AS VARCHAR(8000))
            , f.folderid
        FROM msdb..sysssispackagefolders f
        INNER JOIN cte                   c
	        ON c.folderid = f.parentfolderid
    ) 
    SELECT
        CONCAT(
            c.folderpath
            , '\'
            , p.name                                                   
        )                       AS ssis_path
    FROM cte                                    AS c
    INNER JOIN msdb..sysssispackages            AS p
        ON  c.folderid = p.folderid
    WHERE 
        c.folderpath NOT LIKE '%Data Collector%' 
        AND c.folderpath NOT LIKE '%Maintenance%'
	    AND (LEFT(c.folderpath,1)='\' OR c.folderpath ='')
"@


# Clear output folder
If (Test-Path $output) {
    Remove-Item -Path "$Output\*" -Force -Recurse
} else {
    New-Item -ItemType Directory -Path $Output -Force > $null
}

# Iterate packages
ForEach ($package in $ssis_packages) {
    # Extract package name from DataRow
    $package_name = $package.Item(0)
    $package_name 

    # Build output dtsx path
    $path = "$output\$package_name.dtsx"

    # Create a subfolder
    $folder = Split-Path -Path $path
    If (!(Test-Path $folder)) {
        New-Item -ItemType Directory -Force -Path $folder | Out-Null
    }

    # Run DTUtil
    dtutil /QUIET /SQL "$package_name" /encrypt "FILE;$path;3;$key" /SourceS $Server
}

# Export key to file
$key | Out-File -FilePath "$output\README.txt"