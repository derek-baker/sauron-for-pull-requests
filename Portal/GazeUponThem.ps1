param(
    # TODO: Should be required
    [Parameter(Mandatory=$false)] 
    [string] $repoOwner = 'microsoft',

    # TODO: Should be required
    [Parameter(Mandatory=$false)] 
    [string[]] $repoNames = @('vscode', 'TypeScript'),

    [Parameter(Mandatory=$false)]
    [string] $openPullRequestsOutputFile = "$PSScriptRoot\Visions\OpenPullRequests.json",

    [Parameter(Mandatory=$false)]
    [string] $closedPullRequestsOutputFile = "$PSScriptRoot\Visions\ClosedPullRequests.json"

    # TODO: May be required for private repos
    #[Parameter(Mandatory=$false)]
    #[string] $personalAccessToken = ''
)

$ErrorActionPreference = "Stop";
Set-StrictMode -Version 3

$githubApiVersion = "2022-11-28"
$githubRootUrl = "https://api.github.com/repos/$repoOwner"

[object[][]] $openPullRequestsByRepo = $repoNames | ForEach-Object {
    $repoName = $_

    Invoke-RestMethod `
        -Uri "$githubRootUrl/$repoName/pulls?state=open" `
        -Method 'GET' `
        -Headers @{
            Accept = 'application/vnd.github+json'
            "X-GitHub-Api-Version" = $githubApiVersion
            #Authorization = "Bearer $personalAccessToken"
        } `
        -Verbose | Write-Output 
}

[object[][]] $closedPullRequestsByRepo = $repoNames | ForEach-Object {
    $repoName = $_

    # TODO: &base=develop
    Invoke-RestMethod `
        -Uri "$githubRootUrl/$repoName/pulls?state=closed&per_page=100&sort=created&direction=desc" `
        -Method 'GET' `
        -Headers @{
            Accept = 'application/vnd.github+json'
            "X-GitHub-Api-Version" = $githubApiVersion
            #Authorization = "Bearer $personalAccessToken"
        } `
        -Verbose | Write-Output 
}

# Flattens an Array<Array<object>> into an Array<object>.
$openPullRequestsByRepo `
    | ForEach-Object { $_ | Select-Object }
    | ConvertTo-Json -Depth 10 `
    | Out-File -FilePath $openPullRequestsOutputFile -Verbose -Force

# Flattens an Array<Array<object>> into an Array<object>.
$closedPullRequestsByRepo `
    | ForEach-Object { $_ | Select-Object }
    | ConvertTo-Json -Depth 10 `
    | Out-File -FilePath $closedPullRequestsOutputFile -Verbose -Force
