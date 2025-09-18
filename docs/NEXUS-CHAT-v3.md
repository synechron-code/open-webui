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

 - Move to the Nexus Chat v3 repo root and `origin/nexus-chat-v3` release branch:

```bash
git checkout origin/nexus-chat-v3
```

 - Ensure the upstream Open WebUI remote is syncrhonized and latest tag is available. Nexus Chat v3 should already have the Open WebUI upstream branches and tags from the synchronization with github repo under the `origin` remote).

```bash
git fetch origin --tags
git tag | grep <tag>
```

Replace `<tag>` with the upstream release tag or branch name (for example `v0.6.26`).

2) Create a merge branch

Create an isolated branch from the `origin/nexus-chat-v3` release branch where you perform the merge so the main branch stays stable:

```bash
git checkout -b merge/nexus-chat-v3-<tag>
```

Replace `<tag>` with the upstream release tag or branch name (for example `v0.6.26`).

3) Perform the merge

There are two common strategies: merging the upstream branch directly or using `git rebase` (careful: rebasing rewritten history on a public branch can be disruptive). The merge strategy is safer for collaborative projects.

```bash
git fetch origin
git merge --no-ff origin/<branch-or-tag> -m "Merge origin/<branch-or-tag> into nexus-chat-v3"
```

If the merge completes without conflicts, skip to verification. If there are conflicts, Git will stop and mark conflicted files.

4) Resolve conflicts (practical tips for this repo)

All Nexus Chat v3 code customizations are bracketed by comments.
```
// START Synechron Customization
:
<CODE>
:
// END Synechron Customization
```

or

```
<!-- START Synechron Customization -->
:
<CODE>
:
<!-- END Synechron Customization -->
```

Often there are many conflicts in files that have not been customized for Nexus Chat v3. For files not in the list below, you can just accept all incoming changes.

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
└── docs
    └── NEXUS-CHAT-v3.md
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

- Build and run docker containers

```bash
cd nexuschat-build
./build-and-run.sh
```

6) Create a Pull Request (or push the merge branch)

Push the merge branch and open a PR for the change so teammates and CI can validate it:

```bash
git push origin HEAD
# then open PR from merge/nexus-chat-v3-<tag> into the `nexus-chat-v3` release branch
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


