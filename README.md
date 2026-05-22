# xodex

Switch the OpenAI login used by Codex without moving or replacing the shared
Codex configuration, sessions, logs, caches, plugins, or memories.

`xodex` stores named copies of `~/.codex/auth.json` under
`~/.codex/profile-store`. The shared `~/.codex/config.toml` stays in place.

## Install

Install from the public GitHub repository:

```bash
bash -c 'tmp="$(mktemp -d)" && git clone https://github.com/MichaelErmer/xodex.git "$tmp/xodex" >/dev/null && "$tmp/xodex/install.sh"'
```

The installer places the executable at `~/.codex/bin/xodex`. If that
directory is not already on `PATH`, it links the command into a writable bin
directory that is already on `PATH`, such as `/opt/homebrew/bin`.

## Usage

Open Codex with the currently marked login:

```bash
xodex
```

Switch to a saved login, keep Codex in the foreground, and keep the other saved
inactive ChatGPT-token profiles fresh in the background:

```bash
xodex work
```

Any extra arguments are passed to Codex:

```bash
xodex work --model gpt-5.3-codex
```

Save the current OpenAI login:

```bash
xodex save personal
```

Switch to another saved login:

```bash
xodex use work
```

Create an empty login profile and switch to it:

```bash
xodex new client
```

List saved logins:

```bash
xodex list
```

Show the active marker:

```bash
xodex current
```

Show paths:

```bash
xodex where
```

Refresh saved ChatGPT-token profiles once:

```bash
xodex refresh
xodex refresh work
```

Show the background refresher status:

```bash
xodex refresh-status
```

Fetch saved profile quota once:

```bash
xodex quota
xodex quota work
```

## What Is Switched

Only this file is switched:

```text
~/.codex/auth.json
```

Empty profiles have no `auth.json`. Switching to one clears the active OpenAI
login after backing it up, while leaving shared Codex files in place. Once you
log in while that empty profile is current, switching away saves the new
`auth.json` into that profile automatically.

These stay shared and unchanged:

```text
~/.codex/config.toml
~/.codex/sessions
~/.codex/session_index.jsonl
~/.codex/history.jsonl
~/.codex/log
~/.codex/memories
~/.codex/plugins
```

Before switching, the currently marked profile is saved automatically and the
active `auth.json` is backed up under `~/.codex/profile-store/.backups`.

## Background Refresh

`xodex <profile>` starts Codex normally after switching profiles. In the
background, `xodex` runs one refresher process that periodically checks
saved profiles other than the active profile and refreshes ChatGPT OAuth tokens
with the stored refresh token when they are old or close to expiry.

Refresh defaults:

```text
XODEX_REFRESH_INTERVAL_SECONDS=21600
XODEX_REFRESH_WINDOW_SECONDS=86400
XODEX_REFRESH_LOCK_MAX_AGE_SECONDS=3600
```

Set `XODEX_REFRESH_ENABLED=0` to disable the background refresher. A
stale-safe lock file at `~/.codex/profile-store/.refresh.lock` prevents multiple
processes from refreshing at the same time; if the lock is older than
`XODEX_REFRESH_LOCK_MAX_AGE_SECONDS`, it is ignored and replaced.

## Profile Quota Bar

When Codex is launched from a real terminal, `xodex <profile>` overlays a
right-aligned top status badge. The badge is headed `XODEX | Quotas:`, shows the
cached remaining quota percentage and next reset time for saved profiles, marks
the current profile as `*profile`, and leaves Codex's normal bottom status line
alone. Set `XODEX_QUOTA_OVERLAY_ALIGN=full` to use the old full-width bar.

Quota defaults:

```text
XODEX_QUOTA_BAR=auto
XODEX_QUOTA_OVERLAY_ALIGN=right
XODEX_QUOTA_OVERLAY_MAX_WIDTH=0
XODEX_QUOTA_INTERVAL_SECONDS=900
XODEX_QUOTA_CACHE_MAX_AGE_SECONDS=900
XODEX_QUOTA_LOCK_MAX_AGE_SECONDS=300
XODEX_QUOTA_RESET_DROP_THRESHOLD_PERCENT=20
XODEX_QUOTA_FETCH_TIMEOUT_SECONDS=15
XODEX_QUOTA_BASE_URL=https://chatgpt.com/backend-api
```

Set `XODEX_QUOTA_BAR=0` to run Codex without the top overlay. Quota
overlay max width `0` means use the full terminal width and only truncate when
the quota text is wider than the terminal.
cache files live in `~/.codex/profile-store/.quota`, so multiple
`xodex` instances share the same quota state and will not refetch a
profile before the cache is at least 15 minutes old by default. A stale-safe
lock at `~/.codex/profile-store/.quota.lock` prevents concurrent instances from
refreshing quota state at the same time. If a quota usage percentage drops by
at least `XODEX_QUOTA_RESET_DROP_THRESHOLD_PERCENT` before the previously
advertised reset time, the overlay switches to a blinking `OPENAI RESET` alert
until the next `xodex <profile>` run starts.
