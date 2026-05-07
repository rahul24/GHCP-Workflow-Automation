---
name: cited-research
description: >
  Research a topic with strict citation discipline using Commerce Wiki and MCP
  tools (`enghub-search`, `ado-msazure-search_wiki`, `ado-msazure-search_code`).
  Every claim must have a citation; uncited claims are dropped. Conflicting
  sources are explicitly flagged. Use when: producing a `_research.md` file for
  a work item, answering deep platform questions, or any task where "I think"
  is not good enough.
author: workflow-carveout
version: 1.0.0
date: 2026-05-18
---

# cited-research

## Purpose

Produce a research document where **every assertion is traceable to a source**.
The output is meant to be consumed by humans (PMs) and by the `pm-spec-author`
skill — both rely on the citation chain.

## Inputs

| Name | Required | Notes |
|------|----------|-------|
| `topic_source` | yes | Path to a raw extraction file, or a free-text topic |
| `output_path` | yes if from extraction | Defaults to sibling `_research.md` |

## Procedure

### 1. Frame the questions

From the raw extraction (or topic), enumerate the specific questions that must
be answered. Write them as a bulleted list at the top of a scratch space — this
becomes the spine of the research doc.

### 2. Search in this order

1. **Commerce Wiki** — `commerce_wiki_search`, then `commerce_wiki_read` on matches.
2. **If wiki returns nothing**, automatically call in parallel (do not ask the user):
   - `enghub-search`
   - `ado-msazure-search_wiki`
   - `ado-msazure-search_code`
3. Follow `[[wikilinks]]` and cross-references to depth ≤ 2.

### 3. Citation discipline (non-negotiable)

- **Every paragraph** must end with at least one citation.
- Citation forms:
  - Wiki page: `[[page-name]]`
  - Raw repo doc: `` `agent/WKB/raw/<path>` ``
  - MCP result: `[Title](URL)` with the full source URL
- **If no citation exists, the claim is omitted.** Do not write "it is generally
  understood that…" — drop it.

### 4. Flag conflicts

When two sources disagree on the same fact, render the conflict as a callout
block (markdown has no native yellow):

```markdown
> ⚠️ **Conflicting sources**
> - Source A ([[page-a]]) says: <claim>
> - Source B (`agent/WKB/raw/...`) says: <claim>
> Resolution: <unresolved | favor A because … | needs SME>
```

### 5. Output structure

```markdown
---
research_for: {ado_id or topic}
raw_source: {path to raw extraction, if any}
created: {YYYY-MM-DD}
sources_consulted: {count}
unresolved_conflicts: {count}
---

# Research: {title}

## Questions Driving This Research
- …

## Findings

### {Question 1}
{prose with citations}

### {Question 2}
…

## Conflicts & Gaps
{conflict callouts, or "None"}

## Sources
- [[wiki-page-1]]
- `agent/WKB/raw/...`
- [External title](https://…)
```

### 6. Log the query

Append an entry to `agent/WKB/wiki/log.md`:

```markdown
## [YYYY-MM-DD] research | {topic}
- Driver: {ado_id or "ad-hoc"}
- Pages consulted: …
- Result: answered | partial | gaps identified
```

## Anti-Patterns

- ❌ "Based on general knowledge…" → drop.
- ❌ Hiding a conflict behind a confident assertion → always flag.
- ❌ Citing a wiki page you didn't actually read → only cite pages opened in this session.
- ❌ Long quotations without synthesis — paraphrase, then cite.
