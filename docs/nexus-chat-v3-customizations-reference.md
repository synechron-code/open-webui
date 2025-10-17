# Nexus Chat v3 Customizations vs Upstream Open WebUI v0.6.34
# Reference Document for Future Merges
# Generated: 2025-10-17
# Branch: merge/nexus-chat-v3-v0.6.34
# Base: upstream v0.6.34 tag

## Overview
This document captures all customizations made in Nexus Chat v3 compared to upstream Open WebUI v0.6.34.
Use this as a reference when merging future upstream updates.

## Statistics
- Total files changed: 37
- Total diff lines: 3,714
- Files added: 13
- Files modified: 24
- Insertions: 1,565
- Deletions: 640

## Customization Categories

### 1. Branding & UI Customizations
**Purpose**: Nexus Chat and Synechron branding integration

Added Files:
- static/assets/images/Nexus3.0_Backdrop_gradient.png (990KB background image)
- static/assets/images/Nexus_Chat.png (26KB logo)
- static/assets/images/Nexus_Chat_White.png (46KB logo for dark mode)
- static/assets/images/Synechron_Black_Logo_O.svg (Synechron logo)
- static/assets/images/Synechron_Yellow_White_Logo_O.svg (Synechron logo variant)

Modified Files:
- backend/open_webui/env.py: Added DEFAULT_BACKGROUND_IMAGE, DEFAULT_LOGO_IMAGE, etc.
- backend/open_webui/routers/configs.py: Exposed branding config via API
- src/lib/components/admin/Settings/Interface.svelte: Added branding upload UI (+238 lines)
- src/lib/components/chat/Chat.svelte: Added background image switching logic (+59 lines)
- src/lib/components/chat/Navbar.svelte: Modified logo display (+52 lines)
- src/lib/components/channel/Navbar.svelte: Modified logo display (+44 lines)
- src/lib/components/layout/Sidebar.svelte: Added branding elements (+7 lines)
- src/lib/stores/index.ts: Added isDarkMode store (+8 lines)

### 2. SerpAPI Integration
**Purpose**: Web search functionality using SerpAPI

Modified Files:
- backend/open_webui/retrieval/web/serpapi.py: Custom SerpAPI implementation
- backend/open_webui/config.py: SerpAPI configuration variables

### 3. Configuration Management
**Purpose**: Extended configuration for Nexus Chat features

Modified Files:
- backend/open_webui/config.py: Added custom PersistentConfig instances
- backend/open_webui/main.py: Extended app.state.config with custom fields
- src/lib/apis/configs/index.ts: Added branding config API calls (+63 lines)
- backend/open_webui/routers/configs.py: Enhanced config endpoints

### 4. CI/CD & Infrastructure
**Purpose**: GitLab CI/CD, linting, and documentation

Added Files:
- .gitlab-ci.yml: GitLab CI/CD pipeline configuration
- .hadolint.yaml: Dockerfile linter configuration
- .markdownlint.yaml: Markdown linter configuration
- accept-incoming-except.sh: Script for accepting incoming changes
- catalog-info.yaml: Service catalog metadata
- mkdocs.yml: Documentation configuration
- docs/NEXUS-CHAT-v3.md: Nexus Chat v3 documentation
- nexus-chat-v3-customized-files.txt: List of customized files

### 5. Component Enhancements
**Purpose**: UI/UX improvements and feature additions

Modified Files:
- src/lib/components/admin/Functions/FunctionEditor.svelte: Enhanced editor (+31 lines)
- src/lib/components/workspace/Tools/ToolkitEditor.svelte: Enhanced editor (+30 lines)
- src/lib/components/chat/Settings/Interface.svelte: Settings enhancements (+11 lines)
- src/lib/components/chat/SettingsModal.svelte: Modal updates (+2 lines)
- src/routes/(app)/notes/+layout.svelte: Notes layout changes (+41 lines)
- src/routes/(app)/notes/+page.svelte: Notes page changes (+26 lines)

### 6. Bug Fixes & Refinements
**Purpose**: Fixes integrated into Nexus Chat

Modified Files:
- src/lib/components/chat/Messages/Markdown/HTMLToken.svelte: HTML token handling fix (+6 lines)
- backend/open_webui/retrieval/utils.py: Retrieval utility improvements
- backend/open_webui/routers/files.py: File handling enhancements

### 7. Dependencies
**Purpose**: Package updates and compatibility fixes

Modified Files:
- package.json: Updated TipTap extensions from v2 to v3, updated other dependencies
- package-lock.json: Regenerated lock file with updated dependencies


## File-by-File Merge Guidance

### High Priority Files (Always Preserve Nexus Customizations)

**backend/open_webui/env.py**
- Lines ~817-827: DEFAULT_BACKGROUND_IMAGE, DEFAULT_LOGO_IMAGE variables
- Strategy: Always keep Nexus additions, merge upstream changes around them
- Conflict Resolution: Manual review required for new environment variables

**backend/open_webui/config.py**
- Custom PersistentConfig instances for Nexus branding
- SerpAPI configuration variables
- Strategy: Preserve all Nexus-specific config blocks, merge upstream carefully
- Conflict Resolution: High risk of conflicts, manual review critical

**backend/open_webui/main.py**
- Lines ~657-1207: Extended app.state.config initialization
- Strategy: Preserve Nexus config extensions, merge upstream app state changes
- Conflict Resolution: Manual merge required for app initialization changes

**backend/open_webui/routers/configs.py**
- Enhanced configuration API endpoints
- Branding config exposure
- Strategy: Preserve Nexus endpoint enhancements, merge upstream API changes
- Conflict Resolution: Review new endpoints from upstream for conflicts

**src/lib/components/admin/Settings/Interface.svelte**
- Lines ~451-626: Branding upload controls
- Strategy: Keep all Nexus branding UI, merge upstream settings additions
- Conflict Resolution: Template conflicts likely, manual merge required

**src/lib/components/chat/Chat.svelte**
- Lines ~210-669: Background image switching logic
- onMount/onDestroy: isDarkMode store subscription
- Strategy: Preserve Nexus background logic, merge upstream chat features
- Conflict Resolution: Lifecycle hooks may conflict, careful review needed

**src/lib/stores/index.ts**
- Lines ~93-96: isDarkMode store
- Strategy: Keep isDarkMode store, merge upstream store additions
- Conflict Resolution: Low risk, simple addition

### Medium Priority Files (Review and Merge)

**backend/open_webui/retrieval/web/serpapi.py**
- Custom SerpAPI implementation
- Strategy: If upstream modifies web search framework, adapt Nexus implementation
- Conflict Resolution: May need to refactor to match new upstream patterns

**backend/open_webui/retrieval/utils.py**
- Retrieval utility enhancements
- Strategy: Evaluate if Nexus changes are still needed vs upstream improvements
- Conflict Resolution: Consider adopting upstream improvements

**backend/open_webui/routers/files.py**
- File handling enhancements
- Strategy: Merge upstream file API improvements with Nexus changes
- Conflict Resolution: Review for feature overlap

**src/lib/apis/configs/index.ts**
- Branding config API calls
- Strategy: Preserve Nexus API additions, merge upstream API client changes
- Conflict Resolution: API signature changes may require updates

**src/lib/components/chat/Navbar.svelte**
- Logo display modifications
- Strategy: Keep Nexus logo logic, merge upstream navbar features
- Conflict Resolution: Template structure changes may require manual merge

**src/lib/components/channel/Navbar.svelte**
- Logo display modifications (channel context)
- Strategy: Keep Nexus logo logic, merge upstream changes
- Conflict Resolution: Similar to chat navbar, manual merge likely

### Low Priority Files (Can Adopt Upstream Changes)

**src/lib/components/chat/Messages/Markdown/HTMLToken.svelte**
- HTML token handling fix
- Strategy: Check if upstream has better fix, adopt if available
- Conflict Resolution: Low risk, prefer upstream if they fix same issue

**src/lib/components/admin/Functions/FunctionEditor.svelte**
**src/lib/components/workspace/Tools/ToolkitEditor.svelte**
- Editor enhancements
- Strategy: Review Nexus changes, merge with upstream editor improvements
- Conflict Resolution: Feature-based, review for duplicates or conflicts

**src/routes/(app)/notes/+layout.svelte**
**src/routes/(app)/notes/+page.svelte**
- Notes feature modifications
- Strategy: Merge with upstream notes improvements
- Conflict Resolution: Low conflict risk, layout changes may need review

### Infrastructure Files (Nexus-Specific, No Merge Needed)

These files are Nexus Chat infrastructure and should NOT be merged with upstream:
- .gitlab-ci.yml
- .hadolint.yaml
- .markdownlint.yaml
- accept-incoming-except.sh
- catalog-info.yaml
- mkdocs.yml
- docs/NEXUS-CHAT-v3.md
- nexus-chat-v3-customized-files.txt
- docs/merge-v0.6.34-phase2-report.md

### Binary Assets (Nexus-Specific, No Merge Needed)

These are Nexus Chat branding assets, never merge or delete:
- static/assets/images/Nexus3.0_Backdrop_gradient.png
- static/assets/images/Nexus_Chat.png
- static/assets/images/Nexus_Chat_White.png
- static/assets/images/Synechron_Black_Logo_O.svg
- static/assets/images/Synechron_Yellow_White_Logo_O.svg


## Recommended Merge Workflow for Future Upstream Updates

### Phase 1: Preparation
1. Backup current branch: `git branch backup/pre-merge-vX.Y.Z`
2. Review this customizations document
3. Check upstream CHANGELOG for breaking changes
4. Identify high-risk files from "High Priority" section above
5. Create new merge branch: `git checkout -b merge/nexus-chat-v3-vX.Y.Z`

### Phase 2: Merge Execution
1. Fetch upstream: `git fetch upstream`
2. Attempt merge: `git merge vX.Y.Z`
3. Review conflicts using: `git status` and `git diff --name-only --diff-filter=U`
4. Resolve conflicts file-by-file using guidance above
5. Pay special attention to High Priority files
6. Test build after resolving conflicts

### Phase 3: Verification
1. Run build: `./run.sh` or `./run-compose.sh`
2. Check for import errors and build failures
3. Test all Nexus Chat customizations:
   - Branding display (logos, backgrounds)
   - Dark mode switching
   - SerpAPI integration
   - Admin settings UI
4. Test new upstream features
5. Check browser console and backend logs
6. Document findings in phase report

### Phase 4: Documentation and Review
1. Update this customizations document if needed
2. Create merge phase report documenting:
   - Files with conflicts and resolutions
   - New upstream features tested
   - Any issues discovered
   - Recommendations
3. Create pull request for review
4. Assign reviewers familiar with Nexus customizations

## Key Takeaways for Future Merges

1. **Branding is Critical**: Never lose Nexus/Synechron branding assets and configuration
2. **Config Files are Complex**: backend/open_webui/config.py and main.py require careful manual merging
3. **UI Components Often Conflict**: Svelte components with Nexus additions will need manual merge
4. **SerpAPI is Custom**: Web search framework changes may require SerpAPI adapter updates
5. **Test Thoroughly**: Branding, dark mode, and admin UI must be tested after every merge
6. **Binary Assets**: Never delete or overwrite Nexus branding images
7. **Infrastructure Files**: GitLab CI, linting configs are Nexus-only, never merge
8. **Dependencies**: package.json may need special attention for TipTap and other UI libs

## Reference Files

- Full diff: `/tmp/nexus-chat-customizations.diff` (3,714 lines)
- This summary: `/tmp/nexus-customizations-summary.txt`
- Customized files list: `nexus-chat-v3-customized-files.txt` (in repo)
- Merge documentation: `docs/NEXUS-CHAT-v3.md` (in repo)

## Quick Reference Commands

```bash
# View all Nexus customizations vs upstream v0.6.34
git diff v0.6.34..HEAD

# View only files changed
git diff --name-status v0.6.34..HEAD

# View customizations in specific file
git diff v0.6.34..HEAD -- path/to/file

# Find Nexus-specific code patterns
git grep "Nexus Chat"
git grep "Synechron"
git grep "DEFAULT_BACKGROUND_IMAGE"

# Check if file was modified by Nexus
git diff v0.6.34..HEAD --name-only | grep filename
```

## Contact and Support

For questions about Nexus Chat customizations or merge assistance:
- Review docs/NEXUS-CHAT-v3.md
- Check merge phase reports in docs/
- Consult with Nexus Chat maintainers

---
Document generated: 2025-10-17
Last merge: v0.6.34
Next merge: TBD (follow workflow above)
