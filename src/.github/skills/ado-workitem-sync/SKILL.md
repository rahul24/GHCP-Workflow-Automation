---
name: ado-workitem-sync
description: >
  Pull ADO work items in `Committed` state assigned to the current user from a
  given organization / project / area path and reconcile them against
  `src/tracker/WorkItem-Tracker.md`. Use when: the user asks to "sync
  workitems", "pull ADO tasks", or kicks off the WorkItem-To-Spec workflow.
  Adds new rows for items not yet tracked; skips items already present.
author: workflow-carveout
version: 1.0.0
date: 2026-05-18
---

# ado-workitem-sync

## Purpose

Reconcile the set of ADO work items (filtered by org/project/area-path/state/assignee)
with the local `WorkItem-Tracker.md` so downstream skills always operate on the
most recent un-processed item.

## Inputs

| Name | Default | Notes |
|------|---------|-------|
| `organization` | `microsoft` | ADO organization (used only for link generation, not passed to MCP tools) |
| `project` | `OSGS` | ADO project — passed as `project` |
| `area_path` | `OSGS\Enterprise Commerce\EC FTP` | Area path filter — passed as `areaPath` |
| `state` | `Committed` | Work item state — passed as `state` filter |
| `assignee` | current user | `@Me` — passed as `assignedTo` |
| `tracker_path` | `src/tracker/WorkItem-Tracker.md` | Tracker location |


## Procedure

1. **Query ADO**:
   ```json
   {
     "searchText": "*",
     "project": "{project}",
     "areaPath": "{area_path}",
     "state": "{state}",
     "assignedTo": "@Me",
     "top": 50
   }
   ```
   This returns work items matching the filters. Extract `System.Id`,
   `System.Title`, and `System.CreatedDate` from the results.

   **Fallback**: If the search tool returns no results or errors, use
   `mcp_agency_ado_wit_work_item` with:
   ```json
   {
     "action": "my",
     "project": "{project}",
     "type": "assignedtome",
     "top": 50
   }
   ```
   Then filter the results client-side by area path and state.
   
2. **Read the tracker** at `tracker_path` and parse existing `ADO ID` values from the markdown table.
3. **Diff**: for each fetched item NOT already in the tracker, append a new row.
   - **Do NOT stop the workflow** when an item is already present — just skip it and continue with the next.
4. **Row format** (must match existing columns exactly):

   | Column | Value |
   |--------|-------|
   | ADO ID | numeric id |
   | ADO Link | `https://dev.azure.com/{organization}/{project}/_workitems/edit/{id}` |
   | ADO Title | item title (verbatim) |
   | Created Date | `YYYY-MM-DD` from `System.CreatedDate` |
   | Status | `System.State` |
   | Raw Document | empty until `ado-workitem-extract` runs |
   | Research Document | empty until `cited-research` runs |
   | Spec Document | empty until `pm-spec-author` runs |
   | Is approved to Create a PR? | `No` |

5. **Idempotency**: never duplicate an existing `ADO ID`. Sort new rows by Created Date ascending when appending.

## Output

- Updated `WorkItem-Tracker.md` (markdown table).
- Return the list of newly added ADO IDs so the orchestrator can fan out to the
  extraction skill.

## Notes / Gotchas

- `@Me` resolves to the ADO identity of the authenticated caller, not the local Windows user.
