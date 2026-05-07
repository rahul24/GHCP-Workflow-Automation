# ---------------------------------------------------
# Step 1: Get active PR links from another script
# ---------------------------------------------------

$prLinks = & ".\query-pr.ps1"

if (-not $prLinks -or $prLinks.Count -eq 0) {
    Write-Host "No active PRs found without review docs."
    exit
}

# ---------------------------------------------------
# Step 2: Set working directory
# ---------------------------------------------------

Set-Location "C:\agent\"

# ---------------------------------------------------
# Step 3: Iterate each PR
# ---------------------------------------------------

foreach ($prLink in $prLinks) {

    Write-Host ""
    Write-Host "==============================================="
    Write-Host "Starting Review For PR => $prLink"
    Write-Host "==============================================="
    Write-Host ""

    # Optional unique logfile name per PR
    $safePrName = ($prLink -replace '[^a-zA-Z0-9]', '_')
    $logFile = "copilot_$safePrName.log"

    $prompt = @"
Read and follow the instructions provided in the markdown file placed in agent/workflows/PR-Review-Workflow.md.

Target Active PR Link:
$prLink
"@

    copilot -p $prompt `
      --yolo `
      --experimental `
      --autopilot `
      --effort xhigh `
      --no-ask-user

    Write-Host ""
    Write-Host "Completed Review For PR => $prLink"
    Write-Host ""
}
