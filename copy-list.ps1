[CmdletBinding()]
PARAM(
    [Parameter(Mandatory=$true)]
    [string]$SourceSite,
    [Parameter(Mandatory=$true)]
    [string]$ListName,
    [Parameter(Mandatory=$true)]
    [string]$TargetSite
    
)
BEGIN{
    $ErrorActionPreference = "Stop"
    $TEMPLATENAME = "ListTemplate.xml"

    function Confirm-PnPConnection {
        param(
            [PnP.PowerShell.Commands.Base.PnPConnection]$connection
        )
        try{
            Get-PnPSite -Connection $connection | Out-Null
        }
        Catch{
            Write-Error "Unable to Connect to Source Site with URL $($connection.Url)"
            exit
        }
    }
}
PROCESS{
    # Connect to Target Site and confirm it exists
    $sourceConn = Connect-PnPOnline -Url $SourceSite -Interactive -ReturnConnection
    Confirm-PnPConnection $sourceConn

    # Connect to Target Site and confirm it exists
    $targetConn = Connect-PnPOnline -Url $TargetSite -Interactive -ReturnConnection
    Confirm-PnPConnection $targetConn

    # Confirm List Exists
    $sourceList = Get-PnPList -Identity $ListName -Connection $sourceConn
    if($null -eq $sourceList){
       Write-Error "No list found with an Identity of $ListName." 
       exit
    }
    
    # Create Template From Source
    Get-PnPSiteTemplate -Out $TEMPLATENAME -ListsToExtract $ListName -Handlers Lists -Connection $sourceConn

    # Add Data Rows for List
    Add-PnPDataRowsToSiteTemplate -Path $TEMPLATENAME -List $ListName -Connection $sourceConn

    # Apply Site Template to Target
    Invoke-PnPSiteTemplate -Path $TEMPLATENAME -Connection $targetConn
}
END{
    Disconnect-PnPOnline -Connection $sourceConn
    Disconnect-PnPOnline -Connection $targetConn
}