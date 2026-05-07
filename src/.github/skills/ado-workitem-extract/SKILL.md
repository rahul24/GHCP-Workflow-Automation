---
name: ado-workitem-extract
description: >
  Extract a single ADO work item's Title, Description, and Attachments into a
  raw markdown file under `agent/ADO/{ado_id}/`, then update the `Raw Document`
  cell for that work item in `src/tracker/WorkItem-Tracker.md` to point at
  the file just written. Attachment content (Word, PDF, etc.) is converted to
  markdown and embedded inline — no binary files are kept. Use when: an item
  has been added to `WorkItem-Tracker.md` and needs a raw dump before research
  begins, or when the user asks to "extract ADO {id}".
author: Rahul Sharma
version: 1.8.0
date: 2026-05-20
---

# ado-workitem-extract

## Purpose

Produce a self-contained, citable markdown snapshot of a single ADO work item
so downstream skills (`cited-research`, `pm-spec-author`) never need to re-query
ADO.

## Inputs

| Name | Required | Notes |
|------|----------|-------|
| `ado_id` | yes | Numeric ADO work item id |
| `output_dir` | no | Defaults to `src/ado/` |

If `ado_id` is not provided, pick the most-recent row in `WorkItem-Tracker.md`
whose `Research Document` cell is empty.

## Prerequisites

The skill auto-bootstraps everything it can. The runner only needs Python
on the host; the MCP `ado` tool handles ADO auth on the happy path.

| Tool | Auto-handled by skill? | Notes |
|------|------------------------|-------|
| `ado` MCP tool | n/a (provided by the agent runtime) | Sole auth + fetch path for the work item and attachments. |
| Python 3.x on `PATH` | ❌ | Must be installed on the host. |
| `markitdown[all]` | ✅ | Skill runs `python -c "from markitdown import MarkItDown"` and on `ImportError` runs `pip install --quiet "markitdown[all]"`. |
| Word COM (`Word.Application`) | ✅ detect-only | Probed via `New-Object -ComObject Word.Application`. Required only as a fallback for legacy `.doc` (OLE `D0CF11E0`). If unavailable when a `.doc` is encountered, the skill emits `_(legacy .doc, conversion unavailable on this host)_` rather than failing. |
| `pdftotext` (poppler) | ✅ detect-only | Optional PDF fallback; same graceful-degradation rule. |

### Bootstrap step (run before Procedure step 1)

1. `python --version` succeeds → else fail: "Install Python 3.x and retry".
2. `python -c "from markitdown import MarkItDown"` → on failure run
   `pip install --quiet --disable-pip-version-check "markitdown[all]"` and
   re-check. If the re-check still fails, surface the pip error.
3. Probe optional converters and remember the result:
   - `wordCom = (try { $w = New-Object -ComObject Word.Application; $w.Quit(); $true } catch { $false })`
   - `pdftotext = (Get-Command pdftotext -ErrorAction SilentlyContinue) -ne $null`
   These flags drive per-attachment converter selection in Procedure
   step 3; they never block the run.

Skip the bootstrap entirely when the fetched work item has no `AttachedFile`
relations.

## Procedure

1. **Fetch the work item FIRST** via the `ado` MCP `wit_get_work_item` tool.
   - **You MUST pass `expand=all`** (or `expand=relations` if the MCP variant
     supports it). Bare field requests, and even `expand=relations` in some
     MCP implementations, have been observed to omit the `relations` array
     entirely — causing attachments to be silently dropped. `expand=all` is
     the only reliably correct call.
   - Request fields (in addition to relations): `System.Title`,
     `System.Description`, `System.State`, `System.CreatedDate`,
     `System.AssignedTo`, `System.Tags`.
   - From the response, build the list of `AttachedFile` relations
     (`rel == "AttachedFile"`). Record the attachment URL, filename, and
     `resourceSize` for each.
   - If the MCP cannot reach the work item, fail with the MCP's error message
     — do not introduce alternate auth paths.
2. **Pre-flight directory check** — compute the per-item folder
   `{output_dir}/{ado_id}/` (default: `src/ado/{ado_id}/`).
   - If the folder does NOT exist → create it and continue.
   - If the folder DOES exist, do **not** hard-skip. Open the existing
     `*_raw_extraction.md` and reconcile:
     - Parse the `### {filename} ({size} bytes` headings under `## Attachments`.
     - Compare that set to the `AttachedFile` relations from step 1
       (match on filename + `resourceSize`).
     - If every current ADO attachment is already represented in the file,
       report "extraction already complete for {ado_id}" and exit.
     - Otherwise (missing attachments, size mismatch, or no `## Attachments`
       section at all while ADO reports ≥ 1 attached file) → **re-extract**:
       overwrite the existing `_raw_extraction.md` with a fresh capture that
       includes every current attachment. The folder is the single source of
       truth, so always emit the complete current state; never merge partial
       edits.
   - `--force` always re-extracts unconditionally.
   - All outputs for this work item must live inside this folder — never write
     to `src/ado/` directly.
3. **Convert attachments to markdown (do NOT keep binaries)**:
   - For each `AttachedFile` relation, download the binary into a temp file
     outside the per-item folder (e.g. `$env:TEMP`). Use the MCP download
     path; if that returns base64, write decoded bytes to disk without
     echoing the payload to chat.
   - **Sniff the first 8 bytes (magic number) — do NOT trust the file
     extension.** ADO frequently stores legacy `.doc` files with a `.docx`
     name. Route conversion by detected format:
     - `D0 CF 11 E0 A1 B1 1A E1` → OLE compound (legacy `.doc`, `.xls`,
       `.ppt`). Use Word COM (`wdFormatUnicodeText = 7`, see Word COM note
       below). If Word COM unavailable, emit
       `_(legacy OLE document, conversion unavailable on this host)_`.
     - `50 4B 03 04` → ZIP container (`.docx`, `.xlsx`, `.pptx`, `.zip`).
       Use `python -m markitdown <file> -o <out.md>`.
     - `25 50 44 46` (`%PDF`) → PDF. Use `markitdown`, falling back to
       `pdftotext -layout` if available.
     - UTF-8/UTF-16 BOM or printable-ASCII heuristic (`.txt`/`.md`/`.json`/
       `.yaml`) → embed verbatim inside a fenced code block with a language
       tag derived from the original filename extension.
     - PNG (`89 50 4E 47`), JPEG (`FF D8 FF`), GIF (`47 49 46 38`), or any
       other binary signature → emit `_(image attachment, not converted)_`
       and skip embedding.
   - Embed the converted markdown inline under the `## Attachments` section
     (see Output File Format below).
   - Delete the temp binary after conversion. The per-item folder must contain
     only the `_raw_extraction.md`.

### Word COM invocation (legacy `.doc` fallback)

PowerShell binding for the Word COM `SaveAs` family is fragile. The form
known to work on modern PowerShell (7.x) and Word 16+ is:

```powershell
$w = New-Object -ComObject Word.Application
$w.Visible = $false
$doc = $w.Documents.Open($srcPath, $false, $true)   # ReadOnly = true
$doc.SaveAs2($outTxtPath, 7)                        # wdFormatUnicodeText = 7
$doc.Close($false)
$w.Quit()
```

Do **not** use the legacy `[ref]` parameter form (`SaveAs([ref]$path, [ref]7)`)
— it raises `Cannot convert ... value of type "psobject" to type "Object"`.
Targeting `wdFormatXMLDocument = 12` (.docx) has also been observed to silently
keep the source OLE format, so prefer unicode-text output and embed the result
as plain paragraphs.

4. **Slugify the title** for the filename:
   - Lowercase, replace runs of non-alphanumerics with `-`, trim leading/trailing `-`, cap at 60 chars.
   - Match the style of existing files in `src/ado/` (e.g. `MPSA-entitlement-ask`).
5. **Write** the raw extraction markdown to
   `{output_dir}/{ado_id}/{ado_id}_{slug}_raw_extraction.md`.
6. **Update `src/tracker/WorkItem-Tracker.md`** so the `Raw Document` cell
   for this `ado_id` points at the file just written.
   - Locate the row whose first column matches `{ado_id}`. If no row exists,
     append a new row populated from the fetched fields (`ADO Link`,
     `ADO Title`, `Created Date`, `Status`); leave `Research Document`,
     `Spec Document` empty and `Is approved to Create a PR?` = `No`.
   - Set the `Raw Document` cell to a relative markdown link:
     `[raw](../ado/{ado_id}/{ado_id}_{slug}_raw_extraction.md)`.
   - Preserve every other cell in the row verbatim. Do not reformat unrelated
     rows or the header. Write the file as UTF-8 with no BOM.

## Output File Format

```markdown
---
ado_id: {id}
ado_link: https://dev.azure.com/{org}/{project}/_workitems/edit/{id}
title: "{verbatim title}"
state: {state}
created: {YYYY-MM-DD}
assigned_to: {display name}
tags: [{tag1}, {tag2}]
extracted_at: {YYYY-MM-DD}
---

# {title}

## Description

{HTML-stripped, markdown-converted System.Description}

## Attachments

### {filename} ({size} bytes, {content-type})

{markdown-converted content of the attachment, embedded inline}

<!-- repeat one ### section per attachment; for images or unsupported types,
     emit only the heading plus a one-line note such as
     "_(image attachment, not converted)_" -->
```

## Rules

- **Verbatim**: do not paraphrase Title or Description. This file is the ground truth for citations.
- **HTML → Markdown**: ADO descriptions are HTML. Convert tables, lists, code blocks faithfully.
- **No interpretation**: this skill does not synthesize, summarize, or research.
- **Overwrite policy**: the per-item directory `{output_dir}/{ado_id}/` is
  the single source of truth. The skill skips re-extraction **only when the
  existing `_raw_extraction.md` already covers every current ADO attachment
  (filename + size match)**. Whenever ADO reports an attachment that is not
  yet captured, the skill MUST re-extract and overwrite the file so the
  on-disk state matches ADO. `--force` always re-extracts. Partial merges
  are forbidden — always emit the complete current capture.
- **Always extract attachments when available**: an empty `## Attachments`
  section in the output is permitted only when the work item truly has zero
  `AttachedFile` relations. If ADO reports ≥ 1 attachment, the file MUST
  contain a matching `### {filename} ({size} bytes, ...)` heading and its
  converted body (or an explicit unsupported-type note). Missing attachments
  in the output while ADO reports them is a bug; rerun the skill.
- **Do NOT echo raw binary bytes to the chat/console.** Always convert
  attachments through a proper parser (`markitdown`, `python-docx`, `pdftotext`)
  that emits UTF-8 text, then embed that text. Never pipe raw binary through
  `Write-Host`, `Get-Content -Raw`, or model output — wrong encoding produces
  garbled high-Unicode that trips content-safety filters and aborts the turn.
- **No binaries in the repo.** The per-item folder must end up containing only
  the `_raw_extraction.md`. Temp downloads used for conversion live outside the
  folder and are deleted after use.
- **Encoding discipline**: when writing extracted text, always specify the
  encoding explicitly (`Out-File -Encoding utf8`) and read with the matching
  encoding. Mismatched UTF-8/UTF-16 round-trips are the common failure mode.
