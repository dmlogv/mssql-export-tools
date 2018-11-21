<#
.SYNOPSIS
    Extract SQL Server Integration Service Projects to *.ispac files.


.DESCRIPTION
    The Export-Ispac function uses Microsoft.SqlServer.Management.IntegrationServices 
    to export all SSIS projects from SSISDB Catalog and save them to the file system. 
    
    Optionally, *.ispac files can be extracted to folders.


.PARAMETER server
    Microsoft SQL Server instance name. 

.PARAMETER folder
    Output folder for placing extracted projects.
    By default, will be exported to "ispac" subfolder in the Current working directory.

.PARAMETER unZip
    Unzip exported *.ispac file. $true by default.


.EXAMPLE
    Export-Ispac -server contoso.com -folder ~/ispacs/contoso -unZip false


.NOTES
    User must be able to login to SQL Server and has ssis_admin permission.
#>


Param(
    [Parameter(Mandatory = $true, ValueFromPipeline=$true)]
    [string] $Server,
    [string] $Folder = 'ispacs',
    [bool] $UnZip = $true
)


Function Get-SsisCatalog {
    Param(
        [Parameter(Mandatory = $true)]
        [string] $Server        
    )

    $ns = "Microsoft.SqlServer.Management.IntegrationServices"
    [System.Reflection.Assembly]::LoadWithPartialName($ns) | Out-Null

    # Connection
    $connString = "Data Source=$server;Initial Catalog=master;Integrated Security=SSPI;"
    $conn = New-Object System.Data.SqlClient.SqlConnection $connString

    # Integration Services
    $is = New-Object "$ns.IntegrationServices" $conn
    
    return $is.Catalogs['SSISDB']
}


Function Extract-Zip {
    Param(
        [Parameter(Mandatory=$true)]
        [string] $Zip,

        [Parameter(Mandatory=$true)]
        [string] $Folder
    )
    New-Item -ItemType Directory -Path $Folder -Force > $null
        
    Write-Host ("        Extract: `"{0}`"" -f ($Folder))

    Add-Type -AssemblyName "System.IO.Compression.FileSystem"
    [IO.Compression.ZipFile]::ExtractToDirectory($Zip, $Folder)
}


Function Export-Project {
    Param(        
        [Parameter(Mandatory=$true)]
        [Microsoft.SqlServer.Management.IntegrationServices.ProjectInfo] $Project,

        [Parameter(Mandatory=$true)]
        [string] $Folder, 

        [bool] $UnZip = $true
    )
     
    Write-Host ("    Project: `"{0}`"" -f ($Project.Name))

    $projectFolder = Join-Path $Folder $Project.Parent.Name
    New-Item -ItemType Directory -Path $projectFolder -Force > $null
    
    # ISPAC path with name
    $ispacPath = (Join-Path $projectFolder $Project.Name)
    # ISPAC path with name and extension
    $ispacExtPath = "$ispacPath.ispac"
    
    Write-Host ("        Save: `"{0}`"" -f ($ispacExtPath))

    # ISPAC binary
    $ispac = $Project.GetProjectBytes()
    [System.IO.File]::WriteAllBytes($ispacExtPath, $ispac)

    If ($UnZip) {
        Extract-Zip -Zip $ispacExtPath -Folder $ispacPath    
    }
}


Function Export-Projects {
    Param(
        [Parameter(Mandatory=$true)]
        [Microsoft.SqlServer.Management.IntegrationServices.Catalog] $Catalog,

        [Parameter(Mandatory=$true)]
        [string] $Folder,

        [bool] $UnZip = $true
    )

    ForEach ($ssisFolder in $Catalog.Folders) {
        Write-Host ("Folder: `"{0}`"" -f $ssisFolder.Name)

        ForEach ($project in $ssisFolder.Projects) {
            Export-Project -Project $project -Folder $Folder -UnZip $UnZip
        }
    }
}


# Clear folder
If (Test-Path -Path $Folder) {
    Get-ChildItem -Path $Folder | Remove-Item -Recurse
} else {
    New-Item -ItemType Directory -Path $Folder -Force > $null
}

# Expand path
$Folder = Resolve-Path -Path $Folder

$Catalog = Get-SsisCatalog -Server $Server
Export-Projects -Catalog $Catalog -Folder $Folder -UnZip $UnZip
