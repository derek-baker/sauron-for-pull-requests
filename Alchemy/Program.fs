open FSharp.Data
open System.IO
open System.Text.Json

// Project data on open PRs.
[<Literal>]
let openPrResponseFileRelativePath = "../../api-gateway/Visions/OpenPullRequests.json"
type GithubOpenPrEndpointResponseType = JsonProvider<openPrResponseFileRelativePath>
let openPullRequestsRaw = GithubOpenPrEndpointResponseType.Parse(File.ReadAllText(openPrResponseFileRelativePath))
let now = System.DateTime.UtcNow
let openPullRequests = openPullRequestsRaw |> 
    Seq.map (fun item -> 
        {| 
            Title = item.Title
            CreatedAt = item.CreatedAt
            TimeOpenHours = (now - item.CreatedAt.DateTime).TotalHours
            TimeOpenDays = (now - item.CreatedAt.DateTime).TotalDays; 
            User = item.User.Login
            Url = item.Url
            State = item.State 
        |}) 
            |> Seq.filter (fun item -> item.TimeOpenHours > 36)
            |> Seq.sortByDescending (fun item -> item.TimeOpenHours)

async { 
    let outputFilepath = openPrResponseFileRelativePath.Replace(".json", "_cleaned.json")
    File.WriteAllTextAsync(outputFilepath, JsonSerializer.Serialize(openPullRequests))
        |> Async.AwaitTask
        |> ignore
} |> Async.RunSynchronously


// Project data on last 100 closed PRs.
[<Literal>]
let closedPrResponseFileRelativePath = "../../api-gateway/Visions/ClosedPullRequests.json"
type GithubClosedPrEndpointResponseType = JsonProvider<closedPrResponseFileRelativePath>
let closedPullRequestsRaw = GithubClosedPrEndpointResponseType.Parse(File.ReadAllText(closedPrResponseFileRelativePath))

let outlierValue = -1 
let closedPullRequests = closedPullRequestsRaw |> 
    Seq.map (fun item -> 
        {| 
            Title = item.Title
            CreatedAt = item.CreatedAt
            MergedAt = item.MergedAt
            TimeToMergeInHours = if item.MergedAt.IsSome then (item.MergedAt.Value.DateTime - item.CreatedAt.DateTime).Hours else outlierValue
            Url = item.Url
        |}) 
            
let mergedPullRequests = 
    closedPullRequests |> Seq.filter (fun item -> item.TimeToMergeInHours > outlierValue)

let averageTimeToMergeInHours = 
    mergedPullRequests
        |> Seq.fold (fun acc item -> acc + item.TimeToMergeInHours) 0
        |> (fun timeToMergeInHoursTotal -> timeToMergeInHoursTotal / closedPullRequestsRaw.Length)
            
async { 
    let outputFilepath = closedPrResponseFileRelativePath.Replace(".json", "_cleaned.json")
    let outputData = {| 
        AverageTimeToMergeInHours = averageTimeToMergeInHours 
        MergedPullRequests = mergedPullRequests 
    |}

    File.WriteAllTextAsync(outputFilepath, JsonSerializer.Serialize(outputData))
        |> Async.AwaitTask
        |> ignore
} |> Async.RunSynchronously