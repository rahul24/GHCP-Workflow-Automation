---
name: pm-spec-author
description: >
  Author a PM-facing specification document by synthesizing a raw ADO extraction
  with a cited research document. Use when: a work item has both
  `_raw_extraction.md` and `_research.md` files and needs a `_spec.md`, or the
  user asks to "write the spec for {ado_id}".
author: workflow-carveout
version: 1.0.0
date: 2026-05-18
---

# pm-spec-author

## Purpose

Convert raw work-item content + cited research into a crisp specification that
a Program Manager can take to review, scoping, and engineering hand-off.

## Inputs

| Name | Required | Notes |
|------|----------|-------|
| `raw_path` | yes | `agent/ADO/{id}_{slug}_raw_extraction.md` |
| `research_path` | yes | `agent/ADO/{id}_{slug}_research.md` |
| `output_path` | no | Defaults to `agent/ADO/{id}_{slug}_spec.md` |

## Procedure

1. **Read both inputs in full.** Do not skim. If either is missing, stop and report.
2. **Reconcile**: cross-check the raw description against research findings.
   Any contradiction must be flagged in the spec's *Open Questions* section, not silently resolved.
3. **Structure** the spec using the template below. Sections are mandatory; if
   a section truly has nothing, write `_None identified._` rather than deleting it.
4. **Preserve citations**: every factual claim copied from the research doc
   must carry its citation through. Spec-level recommendations (new content
   not in raw or research) must be marked `[author-inference]`.
5. **Tracker update**: write the spec path back to the `Spec Document` cell of
   `WorkItem-Tracker.md` for this ADO Id.

## Spec Template

```markdown
---
ado_id: {id}
title: "{title}"
state: Draft
spec_author: pm-spec-author
created: {YYYY-MM-DD}
sources:
  raw: {raw_path}
  research: {research_path}
---

# Spec: {title}

## 1. Summary
One paragraph. What is being asked, for whom, why now.

## 2. Background & Context
Synthesis from research. Cited.

## 3. Goals
- …

## 4. Non-Goals
- …

## 5. Requirements
### Functional
- …
### Non-Functional
- …

## 6. Proposed Approach
High-level. May include `[author-inference]` items.

## 7. Open Questions
- Items flagged as conflicting or missing in research.
- Decisions PM must make before engineering picks it up.

## 8. Risks & Dependencies
- …

## 9. Out-of-Scope / Future Work
- …

## 10. References
- Raw: {raw_path}
- Research: {research_path}
- Plus any [[wikilinks]] / URLs surfaced during authoring.
```

## Quality Bar

- **Skimmable**: a PM should grasp the ask from sections 1–4 alone.
- **Decision-ready**: section 7 lists every blocker to approval.
- **No new claims without citation or `[author-inference]` tag.**
- **No marketing language.** Plain, specific verbs.

## Anti-Patterns

- ❌ Pasting the raw description as the spec.
- ❌ Hiding open questions in a footnote.
- ❌ Inventing scope ("we should also do X…") without marking it as inference.
