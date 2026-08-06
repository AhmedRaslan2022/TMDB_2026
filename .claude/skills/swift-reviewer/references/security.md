# Secrets, storage, and privacy

## Secrets — Critical severity, always

Real values live only in `Configs/Secrets.xcconfig`, which is git-ignored.
`Configs/Secrets.example.xcconfig` is committed with placeholders.

Findings, in order of seriousness:

1. A TMDB v4 Read Access Token, session ID, or account ID as a string literal
   anywhere — source, tests, fixtures, snapshots, xcconfig, plist, or a
   commit message. JWT-shaped strings (`eyJ...`) are the usual giveaway.
2. `Secrets.xcconfig` appearing in the diff or no longer matched by
   `.gitignore` (`git check-ignore -q Configs/Secrets.xcconfig`).
3. A token reaching a log line, an error message, or a crash report.
4. A placeholder in `Secrets.example.xcconfig` replaced with a real value.

Auth uses the v4 Read Access Token as an `Authorization: Bearer` header —
never the `api_key` query parameter, which lands in URL logs and analytics.
A URL built with `api_key=` is a finding even if the value is injected.

## Storage placement

| Data | Where | Never |
| --- | --- | --- |
| Session ID, account ID, tokens | `CoreStorage.KeychainManager` (actor) | UserDefaults, SwiftData, source |
| Favorites, recent searches, cached movies | SwiftData | Keychain |
| Feature flags, UI preferences | UserDefaults | — |

- Anything sensitive written to `UserDefaults` is Critical: the plist is
  readable from a backup with no device unlock.
- Keychain items should carry an explicit accessibility class.
  `kSecAttrAccessibleWhenUnlocked` is the right default here;
  `...Always` is deprecated and a finding.
- Deleting a session must clear the Keychain entry, not just the in-memory
  copy — check logout paths.

## Logging

`print`, `NSLog`, and `debugPrint` are banned; the CoreUtilities logger is the
only channel. When reviewing log statements:

- Interpolated values default to **private** under `OSLog` redaction only if
  the logger is configured that way. Anything marked `.public` that carries a
  token, an email, a session ID, or a full request URL is a finding.
- Logging a whole `URLRequest` or its `allHTTPHeaderFields` prints the
  `Authorization` header. Log the path and status code instead.
- Logging a decoded response body can dump user account data.

## Networking

- URLSession only; no third-party networking.
- No custom `URLSessionDelegate` that trusts arbitrary certificates —
  `didReceive challenge` returning `.useCredential` with the server trust
  unconditionally disables TLS validation. Critical.
- `NSAllowsArbitraryLoads` in any Info.plist / `Project.swift` config is a
  finding; TMDB is HTTPS-only.
- Error paths must not surface raw server payloads to the UI.

## Privacy

- Anything read from the user (search text, favorites) stays local unless the
  endpoint genuinely needs it. Flag search terms sent to analytics.
- Recent searches persisted to SwiftData need a user-facing way to clear them.
- New OS-permission usage (photos, contacts, location) requires the matching
  usage-description string in the generated Info.plist via `Project.swift`,
  with text that says what it is actually used for.
