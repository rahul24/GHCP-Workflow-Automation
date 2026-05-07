param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$WorkflowPath
)

Set-Location "C:\Users\rahshar\source\repos\GHCP-Workflow-Automation\src\"

agency copilot -p "Read and follow the instructions provides in the markdown file placed in the $WorkflowPath" `
    --yolo `
    --experimental `
    --autopilot `
    --effort xhigh `
    --no-ask-user

exit
