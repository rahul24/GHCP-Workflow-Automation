# Workflow Demo — Follow-Along Guide

> 🧑‍💼 **Audience**: PMs, program managers, anyone curious about the automation
> 🎯 **Outcome**: You will turn one of your Azure DevOps (ADO) work items -> Spec -> PR -> Review PR -> Close PR without any hassle.

---

## 1. What is this demo about? (The use case)

Today, taking a product idea from an **ADO work item** to a **shipped change** involves a lot of manual steps:

1. PM reads the work item and writes a spec in Word/Confluence.
2. PM checks in the spec for other PMs or engineers to review.
3. PM merges the spec after resolving all the review comments.

Each handoff loses context, adds days, and depends on people being available.

**This demo shows an automation that compresses that pipeline into 5 short steps**, all driven from a chat box:

```
  ADO work item  ──▶  Spec document  ──▶  Pull Request  ──▶  Automated Review
   (you own)         (auto-generated)     (auto-created)      (auto-generated)
                            ▲
                            └── you approve here (one click)
```

By the end of this demo you'll see:
- A PM-quality spec written **for you** from a raw ADO work item
- A real pull request opened on Azure DevOps with that spec attached
- A live dashboard of all active PRs, auto-classified by type and impact
- An automated code/design review of a PR, ready to post as comments

You stay in control — there's exactly **one human approval step** in the middle (you flip a `No` to `Yes` in a table).

---

## 2. Prerequisites (one-time setup)

Please confirm each of these before the demo starts. If any are missing, ask the host for help — most take less than a minute.

### ✅ Accounts & access
- [ ] You have a **Microsoft corporate account** (the one you use for Outlook).
- [ ] You can sign in to **Azure DevOps** at <https://dev.azure.com/microsoft/OSGS> and see the SoftwareRP repository.
- [ ] You have at least **one ADO work item assigned to you** in `Committed` state under the area path `OSGS\Enterprise Commerce\EC FTP`. (If not, ask the host to assign you a demo item.)

### ✅ Software on your laptop
- [ ] **Visual Studio Code** is installed — <https://code.visualstudio.com/>
- [ ] **GitHub Copilot CLI** is installed and you can run `copilot` in a terminal.
- [ ] **Azure CLI** is installed — open a PowerShell terminal and run `az --version` to confirm.
- [ ] **Git** is installed — `git --version` in a terminal should print a version number.
- [] **Agency** is installed or ADO MCP is configured.

### ✅ The repository is on your laptop
- [ ] You have cloned this repo to:
  `C:\repos\GHCP-Workflow-Automation`
  If not, your host will share the clone command.

That's it. You're ready.

---

## 3. Opening the demo environment

1. **Open VS Code.**
2. Use **File → Open Folder…** and pick `C:\Users\<your-alias>\source\repos\GHCP-Workflow-Automation`.
3. Open the built-in terminal: **View → Terminal** (or press `` Ctrl + ` ``).
4. In the terminal, type:
   ```powershell
   cd src
   copilot
   ```
   You'll see a chat prompt appear. **This is where you'll type the demo commands.**
5. Look at the header/footer of the Copilot prompt — it should show a path ending in `…\GHCP-Workflow-Automation\src`. If yes, you're in the right place.

> 💡 Why `src`? All workflow files live under `src/workflows/`, and the workflows expect tracker files like `src/tracker/WorkItem-Tracker.md` to be addressed from this folder.

---

## 4. The demo — 5 simple steps

Each step is: **type one line into the Copilot chat, press Enter, then open one file to see the result.** That's it.

| Step | What you type | What you'll see |
|---|---|---|
| 1 | `@workflows/WorkItem-To-Spec-Workflow.md` | A PM-style spec gets written for your ADO item |
| 2 | *(no typing — just edit one cell in a file)* | You approve the spec |
| 3 | `@workflows/Create-PR-Workflow.md` | A real PR opens on Azure DevOps |
| 4 | `@workflows/PR-Tracker-Workflow.md` | A dashboard of all active PRs updates |
| 5 | `@workflows/PR-Review-Workflow.md` *(+ PR link)* | An automated review of the PR |

---

### Step 1 — Turn your work item into a spec

**What you'll do:** Ask the agent to read your ADO items and write a spec for each.

1. In the Copilot chat, type **exactly** this and press Enter:
   ```
   @workflows/WorkItem-To-Spec-Workflow.md
   ```
2. Wait. The agent will narrate what it's doing — it pulls your ADO items (org `microsoft`, project `OSGS`, area `OSGS\Enterprise Commerce\EC FTP`, state `Committed`), reads them, researches the topic, and writes three documents per item under `agent/ADO/`.
3. When it finishes, open **`src/tracker/WorkItem-Tracker.md`** in VS Code.
   - You should see a **new row** with your work item ID and three filled-in links: `Raw Document`, `Research Document`, `Spec Document` (all pointing into `agent/ADO/`).
4. Click the **Spec Document** link to open the generated spec. Scroll through it — this is the PM-ready document the automation just wrote for you.

> ✅ **Success looks like:** a row in the tracker with all three document columns filled in.

---

### Step 2 — Approve the spec (the only manual step)

**What you'll do:** Tell the system the spec looks good.

1. Stay in `src/tracker/WorkItem-Tracker.md`.
2. Find the column titled **`Is approved to Create a PR?`** on your row.
3. Change the value from `No` to `Yes`.
4. **Save the file** (`Ctrl + S`).

Done. This is the only place a human is in the loop.

---

### Step 3 — Create the pull request

**What you'll do:** Ask the agent to open a real PR using your approved spec.

1. Back in the Copilot chat, type:
   ```
   @workflows/Create-PR-Workflow.md
   ```
2. The agent will create a branch (named like `spec/<ado-id>-<slug>`), commit the three spec files, and open a PR on Azure DevOps. When it's done, it will print a link that looks like:
   ```
   https://dev.azure.com/microsoft/OSGS/_git/<repo>/pullrequest/15810935
   ```
3. **Click that link.** Your browser will open the PR — you'll see the spec as the PR description, the three files attached, and your ADO work item linked.
4. Back in `src/tracker/WorkItem-Tracker.md`, you'll also notice a new **`PR Link`** column has been filled in for your row.

> ✅ **Success looks like:** A live PR in Azure DevOps with your name on it.

---

### Step 4 — Refresh the PR dashboard

**What you'll do:** Ask the agent to update the master dashboard of all active PRs.

1. In the Copilot chat, type:
   ```
   @workflows/PR-Tracker-Workflow.md
   ```
2. When it finishes, open **`agent/docs/PR-Tracker.md`** (the agent will create the `agent/docs/` folder the first time it runs).
3. The PR you just opened in Step 3 should appear in the table. Notice the helpful columns:
   - **PR Classification** — is this a Code Review or a Design Review?
   - **Impact** — LOW / MEDIUM / HIGH (filled in by Step 5)
   - **PR Status** — current state on ADO (Active / Completed / Abandoned)

> ✅ **Success looks like:** your new PR is visible in the tracker.

---

### Step 5 — Get an automated review of the PR

**What you'll do:** Ask the agent to review the PR and prepare review comments.

1. Copy the PR link from Step 3 (or pick any other PR from the tracker).
2. In the Copilot chat, type the following on **two lines** (use Shift+Enter for the new line, then Enter to send):
   ```
   @workflows/PR-Review-Workflow.md
   PR: <paste the PR link here>
   ```
3. When it finishes, open the new review file the agent created in `agent/docs/` — its name will look like `pr-15810935-review-….md`. The path is also written back to the `Review document` column of `PR-Tracker.md`.
4. Scroll to the bottom — you'll see a table of review comments with columns `File | Line | Comment | Is Approved?`.
5. *(Optional)* Type `Yes` into a couple of the `Is Approved?` cells to show how you'd curate which comments actually get posted to the PR. (The host can then run the **Post Approved Comments** workflow to push them.)

> ✅ **Success looks like:** a new review document exists, full of structured feedback.

---

## 5. That's the demo!

Recap of what you just did, in plain English:
1. Took an ADO ticket and got back a PM-quality spec.
2. Approved it with a single edit.
3. Opened a real Azure DevOps pull request automatically.
4. Refreshed a live dashboard of all active PRs.
5. Got an automated review of the PR.

**All five steps were typed into a chat box. No code was written.**

---

## 6. Common hiccups (and how to fix them in 10 seconds)

| What you see | What to do |
|---|---|
| `az: command not found` | Azure CLI isn't installed. Ask the host. |
| Copilot says "no committed ADO items found" | You don't have any work items assigned to you in `Committed` state. Ask the host to assign you the demo item. |
| Browser pops up asking you to sign in | Normal — sign in with your corporate account. |
| The agent seems to hang for a long time | Most steps take 30–90 seconds. Anything beyond 3 minutes — tell the host. |
| You don't see a new row in `WorkItem-Tracker.md` | Save and close the file, then reopen it. VS Code sometimes caches the old version. |

---

## 7. Want to go deeper?

After the demo, you can explore on your own:

- **The workflow definitions** — `src/workflows/*.md` — each file describes exactly what the agent does, in plain English:
  - `WorkItem-To-Spec-Workflow.md` — ADO item → raw/research/spec docs
  - `Create-PR-Workflow.md` — approved spec → ADO pull request
  - `PR-Tracker-Workflow.md` — refresh the master PR dashboard
  - `PR-Review-Workflow.md` — auto-review a PR
- **Your generated documents** — `agent/ADO/<your-item-id>_<slug>_…md` — the raw extract, research, and spec for each work item you process.
- **PR tracker** — `agent/docs/PR-Tracker.md` — the rolling 3-month view of all PRs.
- **The shell scripts** — `src/shell.ps1`, `src/shell-workflow-executor.ps1`, `src/shell-pr-tracker.ps1`, `src/query-pr.ps1` — the same workflows wrapped as PowerShell entry points (used by Task Scheduler).

If you'd like the workflows to run automatically on a schedule (no chat box needed), import the XML files in `src/scheduler/` into **Windows Task Scheduler**:

| File | What it automates |
|---|---|
| `1.WorkItem to Spec.xml` | Step 1 — generate specs |
| `2.Create a PR for approved Specs.xml` | Step 3 — open PRs for approved rows |
| `3.Get active PRs.xml` | Step 4 — refresh the PR dashboard |
| `4.Review PR.xml` | Step 5 — auto-review active PRs |
| `5.Post approved Comments.xml` | Post the comments you marked `Yes` |
| `6.Approve PR.xml` | Auto-approve PRs whose comments are all resolved |

It's a one-time, click-driven setup that keeps the dashboard and reviews fresh on their own.
