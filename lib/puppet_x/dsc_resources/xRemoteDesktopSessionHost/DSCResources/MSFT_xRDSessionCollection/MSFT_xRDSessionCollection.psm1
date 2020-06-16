Import-Module -Name "$PSScriptRoot\..\..\xRemoteDesktopSessionHostCommon.psm1"
if (!(Test-xRemoteDesktopSessionHostOsRequirement)) { Throw "The minimum OS requirement was not met."}
Import-Module RemoteDesktop
$localhost = [System.Net.Dns]::GetHostByName((hostname)).HostName

#######################################################################
# The Get-TargetResource cmdlet.
#######################################################################
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (    
        [Parameter(Mandatory = $true)]
        [ValidateLength(1,15)]
        [string] $CollectionName,
        [Parameter(Mandatory = $true)]
        [string] $SessionHost,
        [Parameter()]
        [string] $CollectionDescription,
        [Parameter()]
        [string] $ConnectionBroker
    )
    Write-Verbose "Getting information about RDSH collection."
    $Collection = Get-RDSessionCollection -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker -ErrorAction SilentlyContinue
    
    if ($Collection) {
        Write-Verbose "Getting collection membership."
        $Member = Get-RDSessionHost -CollectionName $CollectionName -ConnectionBroker $ConnectionBroker -ErrorAction SilentlyContinue | Where-Object {$_.SessionHost -eq $SessionHost} 
    }

    @{
        "CollectionName" = $Collection.CollectionName 
        "CollectionDescription" = $Collection.CollectionDescription
        "SessionHost" = $SessionHost
        "ConnectionBroker" = $ConnectionBroker
        "SessionHostJoined" = -not $null -eq $Member
    }
}


######################################################################## 
# The Set-TargetResource cmdlet.
########################################################################
function Set-TargetResource

{
    [CmdletBinding()]
    param
    (    
        [Parameter(Mandatory = $true)]
        [ValidateLength(1,15)]
        [string] $CollectionName,
        [Parameter(Mandatory = $true)]
        [string] $SessionHost,
        [Parameter()]
        [string] $CollectionDescription,
        [Parameter()]
        [string] $ConnectionBroker
    )
    
    Write-Verbose "Checking for existence of RDSH collection."
    $target = Get-TargetResource @PSBoundParameters

    if ($null -eq $target.CollectionName) {
        Write-Verbose "Creating a new RDSH collection."
        New-RDSessionCollection @PSBoundParameters


        Write-Verbose "Refreshing target state after addning new RDSH collection"
        $target = Get-TargetResource @PSBoundParameters
    }


    If ($target.SessionHostJoined -ne $true)
    {
        Write-Verbose "Adding SessionHost to collection."
        $PSBoundParameters.Remove('CollectionDescription')
        Add-RDSessionHost @PSBoundParameters
    }
}


#######################################################################
# The Test-TargetResource cmdlet.
#######################################################################
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateLength(1,15)]
        [string] $CollectionName,
        [Parameter(Mandatory = $true)]
        [string] $SessionHost,
        [Parameter()]
        [string] $CollectionDescription,
        [Parameter()]
        [string] $ConnectionBroker
    )

    Write-Verbose "Checking for existence of RDSH collection."

    $target = Get-TargetResource @PSBoundParameters

    if ($null -eq $target.CollectionName) {
        Write-Verbose "RDSH Collection does not exist."
        $result = $false
    }
    ElseIf ($target.SessionHostJoined -eq $false)
    {
        Write-Verbose "SessionHost does not belong to RDSH Collection."
        $result = $false
    }
    else
    {
        $result = $true
    }
    
    write-verbose "Test-TargetResource returning:  $result"
    return $result
}

Export-ModuleMember -Function *-TargetResource
