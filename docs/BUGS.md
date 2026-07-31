# BUGS.md — Manual QA & Bug Bash (Sprint 10)

Running log of defects found by hands-on testing. **Ahmed adds rows** as bugs are
found; **Claude** reproduces, fixes on a `sprint-10/bug-<id>-<slug>` branch with a
regression test, and closes the row with the fixing commit.

Severity: **S1** blocker (crash / data loss / feature unusable) · **S2** major
(wrong behavior, no workaround) · **S3** minor (wrong behavior, easy workaround) ·
**S4** polish (cosmetic / nice-to-have).
Status: **Open** → **In progress** → **Fixed** (or **Won't fix**, with a reason).

## How to add a bug  

Copy the template row into the table and fill it in. Minimum useful report:
- **Area** — which feature/screen (Auth, Home, Details, Search, Favorites, Profile, TV, Person, Settings, i18n/RTL, Theme/Icons, Networking…).
- **Steps** — numbered, from a known start state; note device vs simulator and language.
- **Expected vs Actual** — what you wanted, what happened.
- **Severity** — S1–S4.

Template:
```
| B-XX | <area> | <steps to reproduce> | <expected> | <actual> | S? | Open | — |
```

## Open / In-progress bugs

| ID | Area | Steps to reproduce | Expected | Actual | Sev | Status | Fix commit |
|----|------|--------------------|----------|--------|-----|--------|-----------|
| _(none yet — add rows here)_ | | | | | | | |

## Closed bugs

| ID | Area | Summary | Sev | Fixed in | Regression test |
|----|------|---------|-----|----------|-----------------|
| _(none yet)_ | | | | | |

---

## Manual-QA checklist (10.1)

Walk each item on a real device and the simulator, in **both** English and Arabic
(RTL). Tick as covered; file a row above for anything that misbehaves.

### Auth
- [ ] Login via TMDB web auth completes and lands on the tab shell
- [ ] "Continue as guest" works and gates account-only actions
- [ ] Logout clears session (Keychain) and local user data
- [ ] Session restored on relaunch (no re-login needed)

### Home
- [ ] Trending / popular carousels load; posters render
- [ ] Pull-to-refresh / error + retry states behave
- [ ] Tapping a poster pushes Movie Details

### Movie Details
- [ ] Overview, rating ring, cast, similar/recommended all populate
- [ ] Add/remove favorite reflects immediately and persists
- [ ] Rate a movie; rating round-trips
- [ ] Back navigation returns to the correct tab/stack

### Search
- [ ] Typing debounces and returns results; empty + no-results states
- [ ] Recent searches persist and clear
- [ ] Result → Details navigation

### Favorites
- [ ] Added favorites appear; recency order correct
- [ ] Remove updates the list; empty state shows
- [ ] Offline: favorites still readable

### Profile / Watchlist
- [ ] Account info renders (or guest state)
- [ ] Watchlist add/remove + persistence

### TV & Person
- [ ] TV details (seasons, cast) load; navigation works
- [ ] Person filmography (mixed movie/TV) renders; credits navigate

### Settings / i18n / Theme / Icons
- [ ] Switch content language → UI flips to Arabic + RTL live (tab bar rebuilds)
- [ ] Switch back to English restores LTR
- [ ] Dark / Light follows the picker
- [ ] Alternate app icon (Midnight / Sunset) applies without black/blank icon
- [ ] Dynamic Type at large accessibility sizes doesn't clip cards/labels

### Cross-cutting
- [ ] Deep links open the right screen from cold start
- [ ] No secrets in logs (Dev/Test network log shows `•••`, never tokens/session_id)
- [ ] VoiceOver reads meaningful labels on key screens
