# THREAT-MODEL — reusable template

Required before implementing or changing: auth/invites, sharing, uploads/media, location, payments/limits, deep links, sync/APIs, analytics/export, deletion/backup, release infrastructure, native bridges/IPC, auto-update/OTA.

```markdown
# Threats — <feature> / <task ID>
Owner and date:            State: proposed | reviewed | blocked
Components and data-flow diagram (trust boundaries marked):
Personal/sensitive data and whose:
Inputs / outputs:
Who can see, create, edit, delete? (owner/editor/viewer/anonymous):
Abuse cases:
- access another user's object by predictable ID (IDOR/BOLA)
- invite/link leaked, reused, never revoked
- media metadata leaks (EXIF/GPS)
- public logs reveal private data
- replayed webhook / double submit / race on a limit
- tampered client value (price, quota, role)
Impact × probability → priority:
Mitigation per threat (+ ASVS/MASVS reference):
Tests: authorization (A ⇏ B), storage, network, providers:
Residual risk and who accepts it:
Containment / rollback plan:
Evidence executed / not run:
```

Rules: authenticated ≠ authorized — test object by object; hiding a control is not a control; the server enforces; a filled table does not prove protection.
