# Create-PR Workflow

Creates an Azure DevOps Pull Request for every work item in the tracker whose
human reviewer has marked it approved. Runs **after** the WorkItem → Spec
pipeline (`WorkItem-To-Spec-Workflow.md`) has produced raw / research / spec
artifacts and the reviewer has flipped the approval column.

## Inputs

| Name | Default | Notes |
|------|---------|-------|
| `tracker_path` | `src/tracker/WorkItem-Tracker.md` | Source of truth for which items are approved |
| `organization` | `microsoft` | ADO org for PR URL construction |
| `project` | `OSGS` | ADO project |
| `base_branch` | `main` | Target branch for every PR |

## Steps

### 1. Read the tracker and select approved rows

1. Open `src/tracker/WorkItem-Tracker.md`.
2. Parse the markdown table; the `Is approved to Create a PR?` column is the
   only gate. **Select every row where that cell equals `Yes`** (case-insensitive,
   trimmed). Ignore every other row — `No`, blank, and any other value mean
   "not approved; skip".
3. From each selected row capture:
   - `ADO ID`
   - `ADO Title` (used for the PR title and branch slug)
   - `Spec Document` path (the PR body anchor)
   - `Raw Document` and `Research Document` paths (for the PR description)
4. If no rows are approved, exit cleanly with `no approved work items — nothing to do`.

### 2. Create one PR per approved row

For **each** approved row (treat each independently — one failure must not
block the others):

1. **Branch name**: `spec/{ado_id}-{slug}` where `slug` is the same
   lowercased-dash-≤60-char form used by the upstream skills.
2. **Create the branch** off `{base_branch}` if it does not already exist.
   Commit the three artifact files (raw, research, spec) if they are not yet
   committed on that branch. Use the standard repo `Co-authored-by` trailer.
3. **Open the PR** via the ADO MCP (`repo_create_pull_request_by_project` or
   the equivalent `gh`-style tool) with:
   - **Title**: `[Spec] {ADO Title}` (verbatim from the tracker)
   - **Description**: links to the spec, research, and raw extraction files
     plus the work-item link, e.g.
     ```
     Spec for ADO #{ado_id} — [{ADO Title}]({ado_link})

     - Spec: {spec_path}
     - Research: {research_path}
     - Raw extraction: {raw_path}
     ```
   - **Work item link**: associate the PR with `{ado_id}` so ADO traceability
     is preserved.
   - **Reviewers**: leave empty unless the row specifies otherwise; the human
     reviewer who approved the row will add them.
4. Capture the resulting PR URL (`https://dev.azure.com/{organization}/{project}/_git/{repo}/pullrequest/{pr_id}`).

### 3. Write the PR link back to the tracker

For each row processed in step 2:

1. Locate the row in `WorkItem-Tracker.md` by `ADO ID`.
2. **Append a `PR Link` cell** if the column does not yet exist. If adding the
   column for the first time, add it to the header row and to every existing
   data row (use an empty cell `  ` for rows that have no PR yet) so the
   table stays well-formed.
3. Set the `PR Link` cell to the PR URL captured in step 2, formatted as
   `[PR #{pr_id}]({url})`.
4. Do **not** flip `Is approved to Create a PR?` back to `No` — the column is
   human-owned. The presence of a `PR Link` is itself the "already processed"
   signal for re-runs.

### 4. Idempotency

- Re-running the workflow must be safe. If a row already has a `PR Link` set
  AND that PR is still open / merged on ADO, **skip** that row.
- If the `PR Link` cell is set but the linked PR has been abandoned or
  deleted, treat the row as un-processed and create a new PR; overwrite the
  cell with the new link.
- Do not duplicate PRs for the same `(ado_id, branch_name)` pair — query ADO
  first.

## Output

- One ADO PR per approved tracker row.
- Updated `WorkItem-Tracker.md` with a `PR Link` column populated for each
  newly-created PR.
- A short summary printed to chat listing each `{ado_id} → {pr_url}` mapping
  (plus any rows that were skipped and why).

## Notes / Gotchas

- The `Is approved to Create a PR?` column is the **only** approval gate.
  Never create a PR for a row that is not marked `Yes`, even if all three
  document cells are populated.
- The tracker is the single source of truth for which work items have been
  spec'd; never re-derive the approved list from another source.
- One PR per work item — do **not** batch multiple ADO ids into a single PR
  even if they share a branch prefix.
