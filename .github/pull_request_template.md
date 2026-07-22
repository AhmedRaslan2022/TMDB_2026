<!--
  Pick ONE section below and delete the other. See docs/BRANCHING.md.
  Pipeline is forward-only, one hop at a time:
     feature ─▶ develop ─▶ test ─▶ staging ─▶ live
-->

## Type of PR

- [ ] **Feature / fix** → `develop` (squash-merge)
- [ ] **Promotion** (merge-commit, forward-only, one hop):
  - [ ] `develop` → `test`  (mints a **test** version)
  - [ ] `test` → `staging`  (mints a **staging** version → TestFlight when secrets set)
  - [ ] `staging` → `live`  (mints a **live** version → App Store when secrets set)

---

### If this is a feature / fix

**What & why**


**Closes** (sprint task / issue): 

**Checklist**
- [ ] Tests added/updated in this PR; full suite + lint green locally
- [ ] `docs/STATUS.md` updated (task ticked, one-line decision/deviation)
- [ ] No secrets touched; `git diff` on `Configs/` is clean
- [ ] Squash-merging into `develop`

---

### If this is a promotion

- [ ] This is the **next** hop only (not skipping an environment)
- [ ] The source branch's CI is green
- [ ] Using a **merge commit** (not squash), so branch history stays aligned
- [ ] I understand merging mints a new version via `release.yml` (build number = the Actions run number; a `‹env›-v‹marketing›-build.‹n›` tag + GitHub Release; distribution runs only when signing secrets are set)

**Notes for this promotion** (anything QA should watch):

