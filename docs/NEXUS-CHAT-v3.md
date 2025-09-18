## Merging updated releases of Open WebUI into Nexus Chat v3

This document describes a practical, repeatable process to merge upstream releases of Open WebUI into the customized Nexus Chat v3 repository. It covers preparing your branches, performing the merge, resolving conflicts that commonly occur in this project (frontend components, static assets, backend routers), verifying the result, and rolling back if needed.

Checklist
- Ensure working tree is clean (commit or stash local changes)
- Fetch upstream and identify the release/tag/branch to merge
- Create a safe feature branch for the merge
- Perform the merge and resolve conflicts carefully
- Build, lint, and run tests locally
- Create a PR for review and CI verification

1) Prepare your local repo

 - Move to the Nexus Chat v3 repo root and ensure a clean working tree:

```bash
git status --porcelain
git add -A && git commit -m "WIP: save local changes"   # or stash
git stash push -m "wip before upstream merge"         # if you prefer stashing
```

 - Add the upstream Open WebUI remote if it's not already present. Replace URL with the canonical upstream remote:

```bash
git remote add upstream https://github.com/open-webui/open-webui.git
git fetch upstream --tags
```

2) Create a merge branch

Create an isolated branch where you perform the merge so the main branch stays stable:

```bash
git checkout -b merge/upstream-<tag>-into-nexuschat-v3
```

Replace `<tag>` with the upstream release tag or branch name (for example `v0.6.26`).

3) Perform the merge

There are two common strategies: merging the upstream branch directly or using `git rebase` (careful: rebasing rewritten history on a public branch can be disruptive). The merge strategy is safer for collaborative projects.

```bash
git fetch upstream
git merge --no-ff upstream/<branch-or-tag> -m "Merge upstream/<branch-or-tag> into nexuschat-v3"
```

If the merge completes without conflicts, skip to verification. If there are conflicts, Git will stop and mark conflicted files.

4) Resolve conflicts (practical tips for this repo)

Files with Changes or Additions in Nexus Chat v3:
```
origin/open-webui-vX.X.X
├── backend/open_webui
│   └── retrieval
│       └── web
│           ├── serplatform.py
│           └── utils.py
├── routers
│   ├── configs.py
│   ├── files.py
│   ├── config.py
│   ├── env.py
│   └── main.py
├── src
│   ├── lib
│   │   ├── apis
│   │   │   └── configs
│   │   │       └── index.ts
│   │   ├── components
│   │   │   ├── admin
│   │   │   │   └── Settings
│   │   │   │       └── Interface.svelte
│   │   │   ├── channel
│   │   │   │   └── Navbar.svelte
│   │   │   ├── chat
│   │   │   │   ├── Messages
│   │   │   │   │   ├── Markdown
│   │   │   │   │   │   ├── HTMLToken.svelte
│   │   │   │   │   │   ├── Message.svelte
│   │   │   │   │   │   └── UserMessage.svelte
│   │   │   │   └── chat
│   │   │   │       ├── Interface.svelte
│   │   │   │       ├── Chat.svelte
│   │   │   │       ├── Navbar.svelte
│   │   │   │       └── SettingsModal.svelte
│   │   │   └── stores
│   │   │       └── index.ts
│   │   ├── routes
│   │   │   └── notes
│   │   │       ├── +layout.svelte
│   │   │       └── +page.svelte
│   │   └── static
│   │       └── assets
│   │           ├── Nexus_Chat_White.png
│   │           ├── Nexus_Chat.png
│   │           ├── Nexus3.0_Backdrop_gradient.png
│   │           ├── Synechron_Black_Logo_O.svg
│   │           └── Synechron_Yellow_White_Logo_O.svg
│   ├── .gitlab-ci.yml
│   ├── .hadolint.yaml
│   ├── .markdownlint.yaml
│   ├── catalog-info.yaml
│   └── mkdocs.yaml
```
From the provided file tree and diffs, Nexus Chat v3 customizations touch frontend `src/lib/components`, `routes`, `static/assets/images`, and backend `backend/open_webui` routers and retrieval code. Expect conflicts in these areas.

- Use `git status` and `git diff` to list and inspect conflicts:

```bash
git status
git diff --name-only --diff-filter=U
git diff
```

- For Svelte component conflicts (`.svelte` files):
	- Prefer keeping Nexus Chat UI behaviors and styles, but adopt non-breaking bug fixes or accessibility improvements from upstream.
	- If upstream introduced new props/slots or changed store APIs, port those changes into the custom component carefully and test in the app.

- For static assets (images, icons):
	- If both sides changed or renamed assets, prefer the Nexus Chat brand assets unless upstream brings important fixes.
	- Update references in code to match any renamed assets.

- For backend Python changes in `backend/open_webui`:
	- Merge logic-level changes from upstream (security fixes, protocol changes). If Nexus Chat added custom routes or wrappers, keep those and adapt upstream changes into them.
	- Run unit tests or a quick smoke run of the backend to ensure imports and endpoints behave as expected.

- Typical merge conflict workflow:

```bash
# Open each conflicted file, make decisions, then mark resolved
git add <file1> <file2> ...
# when all resolved
git commit
```

If you want to abort the merge and return to pre-merge state:

```bash
git merge --abort
# or if that doesn't work
git reset --merge
```

5) Verify locally (quality gates)

- Frontend
	- Install deps and run the build for the UI part that Nexus Chat uses (project root or `nexuschat` frontend):

```bash
# example - run from repo root or nexuschat folder if applicable
npm ci
npm run build
npm run dev     # smoke test in browser if needed
```

- Backend
	- Create a virtualenv, install requirements, and run quick tests or start the server to confirm endpoints:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pytest -q   # minimal test run if tests exist
```

- Lint & formatting
	- Run any configured linters (eslint, ruff, mypy) and address failures.

6) Create a Pull Request (or push the merge branch)

Push the merge branch and open a PR for the change so teammates and CI can validate it:

```bash
git push origin HEAD
# then open PR from merge/upstream-... into your `main` or `release` branch
```

7) Rollback and emergency fixes

If something goes wrong after merging and you've already pushed:

- If the merge branch hasn't been merged to the main production branch yet, you can fix on the merge branch and push updates.
- If you merged into main and need to revert the merge commit:

```bash
# find the merge commit hash
git log --oneline
git revert -m 1 <merge-commit-hash>
git push origin main
```

If you need to reset main to the previous commit (destructive; avoid on shared branches):

```bash
git reflog    # find prior commit
git reset --hard <sha-before-merge>
git push --force-with-lease origin main
```

8) Automation and long-term maintenance

- Keep an `upstream` remote configured and periodically fetch and create merge branches for new upstream releases.
- Consider a small merge helper script that:
	- fetches upstream
	- creates the merge branch
	- runs build/test steps automatically
	- opens a draft PR using GitHub CLI or GitHub API

Example quick script (bash) idea (not added to repo here):

```bash
#!/usr/bin/env bash
set -euo pipefail
TAG="$1" # e.g. v0.6.26
git fetch upstream
BRANCH="merge/upstream-${TAG}-into-nexuschat-v3"
git checkout -b "$BRANCH"
git merge --no-ff "upstream/${TAG}"
# run build/test commands here and exit non-zero on failure
```

9) Acceptance checklist before merging to production branch

- All conflicts resolved and code compiles
- Frontend smoke-tested in a browser
- Backend endpoints respond correctly in a local run
- Linters and tests pass or have an approved exception
- PR reviewed by a teammate and CI green

Notes and assumptions
- This guide assumes `upstream` is the canonical Open WebUI remote. Replace remote/branch names as appropriate for your workflow.
- When in doubt, prefer the Nexus Chat brand and functionality for UX or brand assets, and prefer upstream fixes for security and platform-level bugs. Document each such decision in the PR description for future audits.

If you want, I can add a small helper script in `nexuschat/scripts/` and a checklist template for PR descriptions to speed the process—tell me if you want that and I'll add it.

