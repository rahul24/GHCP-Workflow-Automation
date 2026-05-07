# WorkItem → Spec Workflow

Thin orchestrator that chains four reusable skills to turn an ADO work item into
a PM-ready specification document. Each phase is owned by a dedicated skill in
`agent/.github/skills/` — see each skill's `SKILL.md` for inputs, outputs, and
quality bars.

> **Default behavior**: invoking this workflow **always kicks off the full pipeline end-to-end** (Sync → Extract → Research → Author Spec). Do not stop after any individual phase, do not ask the user for confirmation between phases, and do not treat "no new items from sync" as a stop condition — process every un-processed row in `WorkItem-Tracker.md` (any row missing a `Raw Document`, `Research Document`, or `Spec Document` entry) through the remaining phases. Skills remain individually idempotent and may be invoked à la carte, but the workflow itself runs all four steps every time.

## Pipeline

```
┌──────────────────────┐   ┌────────────────────────┐   ┌────────────────┐   ┌───────────────┐
│  ado-workitem-sync   │ → │ ado-workitem-extract   │ → │ cited-research │ → │ pm-spec-author│
│ (tracker reconcile)  │   │ (raw markdown dump)    │   │ (citations)    │   │ (PM spec)     │
└──────────────────────┘   └────────────────────────┘   └────────────────┘   └───────────────┘
        │                            │                          │                     │
        ▼                            ▼                          ▼                     ▼
 WorkItem-Tracker.md       ADO/{id}_{slug}_raw_…       ADO/{id}_{slug}_research…  ADO/{id}_{slug}_spec…
```

## Steps

1. **Sync** — invoke the [`ado-workitem-sync`](../.github/skills/ado-workitem-sync/SKILL.md) skill.
   - Default filters: org `microsoft`, project `OSGS`, area path `OSGS\Enterprise Commerce\EC FTP`, state `Committed`, assigned to current user.
   - Output: new rows appended to `src/tracker/WorkItem-Tracker.md`. Already-tracked items are skipped (the workflow does **not** stop on a hit).

2. **Extract** — for **every** un-processed row in the tracker (newly added by step 1 **or** pre-existing rows without a `Raw Document` path), invoke
   [`ado-workitem-extract`](../.github/skills/ado-workitem-extract/SKILL.md).
   - Output: `agent/ADO/{ado_id}_{slug}_raw_extraction.md` plus any attachments under `agent/ADO/attachments/{ado_id}/`.

3. **Research** — invoke [`cited-research`](../.github/skills/cited-research/SKILL.md) with the raw extraction as input.
   - Output: `agent/ADO/{ado_id}_{slug}_research.md` with strict citation discipline and explicit conflict callouts.
   - Update the tracker's `Research Document` cell with the relative path.

4. **Author Spec** — invoke [`pm-spec-author`](../.github/skills/pm-spec-author/SKILL.md) with the raw + research files.
   - Output: `agent/ADO/{ado_id}_{slug}_spec.md`.
   - Update the tracker's `Spec Document` cell with the relative path.

## Conventions

- **File naming**: `{ado_id}_{slug}_{phase}.md` where `slug` is the lowercased, dash-separated, ≤60-char form of the ADO title. Match the style of existing files in `agent/ADO/`.
- **Markdown highlighting for conflicts**: use a `> **Conflicting sources**` blockquote (markdown has no native yellow).
- **Approval gate**: the `Is approved to Create a PR?` tracker column is owned by the human reviewer; this workflow only writes `No` on row creation and never flips it.

## Re-running

The workflow always runs **all four phases** when invoked; the pipeline is idempotent at the skill level so re-runs are safe:

- `ado-workitem-sync` deduplicates by ADO Id.
- `ado-workitem-extract` refuses to overwrite without `--force`.
- `cited-research` and `pm-spec-author` overwrite their own outputs and re-log.

To force a full re-run for one item, delete its three `agent/ADO/` files and
re-invoke from step 2.
