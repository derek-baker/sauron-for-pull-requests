param(
    # [Parameter(Mandatory=$true)]
    # [string] $personalAccessToken,  # TODO: Env var?

    [Parameter(Mandatory=$false)] 
    [string] $repoOwner = 'microsoft',

    [Parameter(Mandatory=$false)] 
    [string] $githubApiVersion = '2022-11-28',

    [Parameter(Mandatory=$false)] 
    [string] $githubRootUrl = "https://api.github.com/repos/$repoOwner",

    [Parameter(Mandatory=$false)] 
    [string[]] $repoNames = @('vscode', 'TypeScript'),

    [Parameter(Mandatory=$false)]
    [string] $openPullRequestsOutputFile = "$PSScriptRoot\Visions\OpenPullRequests.json",

    [Parameter(Mandatory=$false)]
    [string] $closedPullRequestsOutputFile = "$PSScriptRoot\Visions\ClosedPullRequests.json"
)

$ErrorActionPreference = "Stop";
Set-StrictMode -Version 3

function Get-OpenPullRequests() {
    [object[][]] $openPullRequestsByRepo = $repoNames | ForEach-Object {
        $repoName = $_
    
        Invoke-RestMethod `
            -Uri "$githubRootUrl/$repoName/pulls?state=open" `
            -Method 'GET' `
            -Headers @{
                Accept = 'application/vnd.github+json'
                "X-GitHub-Api-Version" = $githubApiVersion
                # Authorization = "Bearer $personalAccessToken"
            } `
            -Verbose | Write-Output # Being explicit about the fact that pipeline output is being written into the variable.
    }
    # Flattens an Array<Array<object>> into an Array<object>.
    $openPullRequestsByRepo `
        | ForEach-Object { $_ | Select-Object } `
        | ConvertTo-Json -Depth 10 `
        | Out-File -FilePath $openPullRequestsOutputFile -Verbose -Force
}
Get-OpenPullRequests

function Get-ClosedPullRequests() {
    [object[][]] $closedPullRequestsByRepo = $repoNames | ForEach-Object {
        $repoName = $_
    
        # TODO: &base=develop
        Invoke-RestMethod `
            -Uri "$githubRootUrl/$repoName/pulls?state=closed&per_page=100&sort=created&direction=desc" `
            -Method 'GET' `
            -Headers @{
                Accept = 'application/vnd.github+json'
                "X-GitHub-Api-Version" = $githubApiVersion
                # Authorization = "Bearer $personalAccessToken"
            } `
            -Verbose | Write-Output 
    }
    
    #Flattens an Array<Array<object>> into an Array<object>.
    $closedPullRequestsByRepo `
        | ForEach-Object { $_ | Select-Object } `
        | ConvertTo-Json -Depth 10 `
        | Out-File -FilePath $closedPullRequestsOutputFile -Verbose -Force
}
Get-ClosedPullRequests
