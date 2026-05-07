$markdownFile = ".\docs\PR-Tracker.md"

# -----------------------------
# Generic Markdown Table Parser
# -----------------------------
function Parse-MarkdownTable {
    param(
        [string[]]$Lines
    )

    # Find first valid header row
    $headerLine = $Lines | Where-Object {
        $_ -match '^\|.*\|$' -and $_ -notmatch '^\|--'
    } | Select-Object -First 1

    if (-not $headerLine) {
        throw "Markdown table header not found."
    }

    $headerIndex = [array]::IndexOf($Lines, $headerLine)

    # All valid data rows after header + separator
    $dataLines = $Lines[($headerIndex + 2)..($Lines.Count - 1)] | Where-Object {
        $_ -match '^\|.*\|$' -and $_ -notmatch '^\|--'
    }

    # Parse dynamic headers
    $headers = $headerLine.Trim('|').Split('|') | ForEach-Object { $_.Trim() }

    $result = @()

    foreach ($line in $dataLines) {
        $values = $line.Trim('|').Split('|') | ForEach-Object { $_.Trim() }

        $row = [ordered]@{}

        for ($i = 0; $i -lt $headers.Count; $i++) {
            $header = $headers[$i]

            if ($i -lt $values.Count) {
                $row[$header] = $values[$i]
            }
            else {
                $row[$header] = ""
            }
        }

        $result += [PSCustomObject]$row
    }

    return $result
}

# -----------------------------
# Load Markdown
# -----------------------------
$lines = Get-Content $markdownFile

$prObjects = Parse-MarkdownTable -Lines $lines

# -----------------------------
# Normalize field access safely
# -----------------------------
$normalizedPRs = foreach ($row in $prObjects) {

    [PSCustomObject]@{
        PR               = $row.PR
        Link             = $row.Link
        Author           = $row.Author
        Date             = if ($row.Date) { [datetime]$row.Date } else { $null }
        PRStatus         = $row.'PR Satus'
        PRClassification = $row.'PR Classification'
        ReviewDocument   = $row.'Review document'
        Impact           = $row.Impact
        ApprovedToPost   = $row.'Is approved to post review comment?'
    }
}

# -----------------------------
# Business Filter
# -----------------------------
$latestPendingReviewPR = $normalizedPRs |
    Where-Object {
        $_.PRStatus -eq "Active" -and
        [string]::IsNullOrWhiteSpace($_.ReviewDocument)
    } |
    Sort-Object Date -Descending |
    Select-Object -First 5 |
    Select-Object -ExpandProperty Link

$latestPendingReviewPR