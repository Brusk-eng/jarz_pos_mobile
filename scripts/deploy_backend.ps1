param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('staging', 'production')]
    [string]$Environment,

    [switch]$PlanOnly,
    [switch]$SkipMigrate,
    [switch]$SkipBackup,
    [switch]$ForceReinstallApps,
    [switch]$ForceMigrate,
    [switch]$Yes,
    [string]$SshKeyPath,

    # Pin the deploy to a known commit. Without it, "deploy commit X" is a
    # statement of intent, not a constraint: this script ships whatever the
    # remote branch head happens to be at the instant it pulls, and several
    # Claude chats push to the same `main`. On 2026-08-27 a production deploy
    # planned at 4349631 shipped 778bb30 because another chat pushed 1m49s
    # after the plan run — which also put production a commit AHEAD of
    # staging, so a change reached prod having never run on staging.
    #
    # Accepts a 7-40 char hex SHA, prefix-matched against the resolved remote
    # head of each deployed app; the run is refused before the backup and
    # before the pull if none matches, so a refused run changes nothing.
    [string]$Commit,

    # Pin for jarz_social, the optional fourth app. -Commit above only ever pins
    # jarz_pos; jarz_social lives in its own repo with its own history, so it gets
    # its own tripwire, same semantics as -Commit: the SHA (7-40 hex, prefix match)
    # must equal jarz_social's remote head or the run is refused before the clone,
    # the backup and the pull. Passing it also OPTS jarz_social INTO this deploy.
    # Without it, jarz_social is deployed only where it is already installed
    # (unpinned, like hrms), so a server that has no deploy key for the private
    # repo yet can still take a POS hotfix.
    [string]$SocialCommit
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path -Parent $repoRoot
if (-not $SshKeyPath) {
    $SshKeyPath = Join-Path $workspaceRoot 'ERPNext-stg.pem'
}

$remoteDir = '/home/ubuntu/erpnext_docker'
$remoteAppsDir = '/var/lib/docker/volumes/erp_apps/_data'
$serviceNames = @('backend', 'queue-short', 'queue-long', 'scheduler')
$gitSshCommand = "ssh -i /home/ubuntu/.ssh/id_ed25519 -o UserKnownHostsFile=/home/ubuntu/.ssh/known_hosts -o StrictHostKeyChecking=accept-new"

if (-not (Test-Path $SshKeyPath)) {
    throw "SSH key not found at $SshKeyPath"
}

# Apps pulled on every deploy. This list is deliberately SHARED by staging and
# production: an app production pulls must be exercised on staging first, or its
# upstream commits reach production having never run anywhere else. Until
# 2026-07-15 staging's list omitted hrms while production's included it, so 24
# upstream frappe/hrms commits shipped straight to production — and any hrms
# schema change would have hit `bench migrate` for the first time on prod.
# Keep this single list; do not re-introduce a per-environment variant.
# jarz_courier MUST stay after jarz_pos: it declares required_apps = ["jarz_pos"]
# and `bench install-app` fails if a required app is not installed yet.
#
# An app listed here must be readable by the servers' /home/ubuntu/.ssh/id_ed25519.
# Listing one that is not makes Ensure-AppCloned fail on the clone, which aborts
# EVERY backend deploy including a POS hotfix — that happened on 2026-08-05 while
# jarz_courier was still a private repo the servers had no key for. Confirm with
# `git ls-remote` from the server before adding an app here.
# jarz_courier MUST stay after jarz_pos: it declares required_apps = ["jarz_pos"]
# and `bench install-app` fails if a required app is not yet installed.
#
# An app listed here must be readable by the servers' id_ed25519. Listing one that
# is not makes Ensure-AppCloned fail on the clone, which aborts EVERY backend
# deploy including a POS hotfix. Confirm with `git ls-remote` from the server
# before adding an app here.
$deployedApps = @('jarz_pos', 'jarz_woocommerce_integration', 'hrms', 'jarz_courier')

# Upstream apps held at a known-good commit instead of following their branch tip.
#
# hrms follows frappe/hrms `version-16`, but Frappe itself is baked into the Docker
# image and only moves when the image is rebuilt. On 2026-11-18 hrms 16.60.0
# (1b2d7e0) shipped a patch adding an Employee field of type "Vue Component", which
# the image's Frappe does not know: `bench migrate` died halfway on staging, and the
# same unpinned pull would have hit production on the next backend deploy from any
# chat. a01032 is what production ran then. Move a pin only together with a Frappe
# image that the new commit's patches have been migrated against on staging.
#
# A pinned app whose volume is AHEAD of its pin (staging after that failed run) is
# moved back to the pin with `git reset --keep`, which keeps the branch name and
# refuses if a tracked file was edited on the volume.
$pinnedAppHeads = @{
    'hrms' = 'a01032350ba1b799345b862cb122fa408bf6780e'
}

# Clone URLs for first-time bootstrap. Only consulted when an app in $deployedApps
# is genuinely absent from the server, so an app already on disk (hrms) needs no
# entry. An app that IS missing and has no entry here fails with a clear message
# instead of a cryptic `rev-parse` error out of Resolve-GitTarget.
#
# Order in $deployedApps is load-bearing for bootstrap: `bench install-app` fails
# if an app's `required_apps` are not installed yet, so a dependent app must be
# listed after the app it depends on.
$appRepos = @{
    'jarz_pos'                     = 'git@github.com:poparab/jarz_pos.git'
    'jarz_woocommerce_integration' = 'git@github.com:poparab/Woo_ERPNext.git'
    'jarz_courier'                 = 'git@github.com:poparab/jarz_courier.git'
    'jarz_social'                  = 'git@github.com:poparab/jarz_social.git'
}

# jarz_social: optional fourth app, private repo, NOT in $deployedApps. It joins the
# run only when -SocialCommit is given or it is already cloned on the server (see
# "jarz_social opt-in" below). Declares no required_apps beyond frappe, no pip deps,
# no JS build assets, so the generic clone -> pip -e -> apps.txt -> install-app
# bootstrap is all it needs.
$socialApp = 'jarz_social'

# Per-app SSH key override. GitHub refuses the same deploy key on two repos, and the
# servers' default id_ed25519 is already bound to the other private repos, so
# jarz_social needs its own read-only deploy key. Apps absent from this table use
# the default key exactly as before.
$appSshKeys = @{
    'jarz_social' = '/home/ubuntu/.ssh/id_ed25519_jarz_social'
}

function Get-GitSshCommand([string]$AppName) {
    if ($appSshKeys.ContainsKey($AppName)) {
        # IdentitiesOnly: offer ONLY this key, so GitHub cannot authenticate us as
        # the default key's repo and answer "Repository not found" for a repo that
        # key was never granted.
        return "ssh -i $($appSshKeys[$AppName]) -o IdentitiesOnly=yes -o UserKnownHostsFile=/home/ubuntu/.ssh/known_hosts -o StrictHostKeyChecking=accept-new"
    }
    return $gitSshCommand
}

$config = switch ($Environment) {
    'staging' {
        @{
            ServerIp = '13.36.219.136'
            Domain = 'erpstg.orderjarz.com'
            CustomApps = $deployedApps
            RequiresBackup = $false
        }
    }
    'production' {
        @{
            ServerIp = '13.36.132.13'
            Domain = 'erp.orderjarz.com'
            CustomApps = $deployedApps
            RequiresBackup = $true
        }
    }
}

$sshTarget = "ubuntu@$($config.ServerIp)"

function Write-Info([string]$Message) {
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warn([string]$Message) {
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Step([string]$Message) {
    Write-Host "[STEP] $Message" -ForegroundColor Cyan
}

function Invoke-Remote {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [switch]$IgnoreExitCode
    )

    $output = ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i $SshKeyPath $sshTarget $Command 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0 -and -not $IgnoreExitCode) {
        throw "Remote command failed ($exitCode): $Command`n$($output -join "`n")"
    }

    return ($output -join "`n").TrimEnd()
}

# bench draws progress bars by redrawing one line; with no TTY on the far side of
# ssh every redraw arrives as a separate line -- a no-op staging migrate emitted
# 1,529 progress lines against 89 lines of real content. Collapse each run to its
# final state so a patch's summary is not buried in bar spam. Non-progress lines
# are passed through untouched.
function Compress-MigrateProgress([string]$Text) {
    if (-not $Text) { return $Text }

    $progressPattern = '^(?<label>.*?):\s*\[[ =#]*\]\s*\d+%\s*$'
    $lines = $Text -split "`r?`n"
    $kept = New-Object 'System.Collections.Generic.List[string]'

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $progressPattern) {
            $label = $Matches['label']
            # Drop this redraw only when the next line continues the same bar.
            if (($i + 1) -lt $lines.Count -and $lines[$i + 1] -match $progressPattern -and $Matches['label'] -eq $label) {
                continue
            }
        }
        $kept.Add($lines[$i])
    }

    return ($kept -join [Environment]::NewLine)
}

function ConvertTo-BashLiteral([string]$Value) {
    $singleQuote = [char]39
    $replacement = ([string]$singleQuote) + '"' + ([string]$singleQuote) + '"' + ([string]$singleQuote)
    return "$singleQuote" + ($Value -replace [regex]::Escape("$singleQuote"), $replacement) + "$singleQuote"
}

function Resolve-ContainerName([string]$ServiceName) {
    $containerName = (Invoke-Remote "docker ps --format '{{.Names}}' | grep -E 'erp[-_]$ServiceName[-_][0-9]+' | head -1").Trim()
    if (-not $containerName) {
        throw "Container for service '$ServiceName' not found"
    }

    return $containerName
}

function Resolve-GitTarget([string]$AppName) {
    $appPath = "$remoteAppsDir/$AppName"
    $branchName = (Invoke-Remote "sudo git -c safe.directory=$appPath -C $appPath rev-parse --abbrev-ref HEAD").Trim()
    $headBefore = (Invoke-Remote "sudo git -c safe.directory=$appPath -C $appPath rev-parse HEAD").Trim()
    $remoteNames = Invoke-Remote "sudo git -c safe.directory=$appPath -C $appPath remote"

    if ($remoteNames -match '(?m)^upstream$') {
        $remoteName = 'upstream'
    }
    elseif ($remoteNames -match '(?m)^origin$') {
        $remoteName = 'origin'
    }
    else {
        throw "No git remote found for $AppName at $appPath"
    }

    return @{
        AppName = $AppName
        AppPath = $appPath
        BranchName = $branchName
        RemoteName = $remoteName
        HeadBefore = $headBefore
        HeadAfter = $headBefore
        RemoteHead = $headBefore
        PendingUpdate = $false
        Changed = $false
        RequiresPipInstall = $false
        SchemaChanged = $false
    }
}

function Convert-GitHubRemoteToSsh($GitTarget) {
    $remoteUrl = (Invoke-Remote "sudo git -c safe.directory=$($GitTarget.AppPath) -C $($GitTarget.AppPath) remote get-url $($GitTarget.RemoteName)").Trim()
    if (-not $remoteUrl) {
        throw "Could not resolve remote URL for $($GitTarget.AppName)"
    }

    if ($remoteUrl -match '^https://github\.com/([^/]+)/(.+?)(?:\.git)?$') {
        $sshUrl = "git@github.com:$($Matches[1])/$($Matches[2]).git"
        Write-Info "Switching $($GitTarget.AppName) remote $($GitTarget.RemoteName) to SSH"
        Invoke-Remote "sudo git -c safe.directory=$($GitTarget.AppPath) -C $($GitTarget.AppPath) remote set-url $($GitTarget.RemoteName) $sshUrl" | Out-Null
        return $sshUrl
    }

    return $remoteUrl
}

function Get-RemoteBranchHead($GitTarget) {
    $lsRemote = (Invoke-Remote "sudo GIT_SSH_COMMAND='$(Get-GitSshCommand $GitTarget.AppName)' git -c safe.directory=$($GitTarget.AppPath) -C $($GitTarget.AppPath) ls-remote $($GitTarget.RemoteName) refs/heads/$($GitTarget.BranchName)").Trim()
    if (-not $lsRemote) {
        throw "Could not resolve remote branch head for $($GitTarget.AppName)"
    }

    return ($lsRemote -split '\s+')[0]
}

function Assert-RequestedCommit($GitTargets, $RequestedCommit) {
    # Enforce -Commit against the remote heads this run actually resolved.
    #
    # Called after every app's RemoteHead is known but BEFORE the backup and
    # before any pull, so a mismatch costs nothing: the server is untouched.
    # Prefix-matched because callers naturally quote the short SHA that git
    # log and the GitHub UI show them.
    if (-not $RequestedCommit) { return }

    $wanted = $RequestedCommit.Trim().ToLowerInvariant()
    if ($wanted -notmatch '^[0-9a-f]{7,40}$') {
        throw "-Commit must be a hex git SHA of 7-40 characters; got '$RequestedCommit'."
    }

    $matched = @($GitTargets | Where-Object { $_.RemoteHead.ToLowerInvariant().StartsWith($wanted) })
    if ($matched.Count -gt 0) {
        Write-Info "-Commit $wanted confirmed: $($matched[0].AppName) remote head is $($matched[0].RemoteHead)"
        return
    }

    $listing = (@($GitTargets | ForEach-Object { "  $($_.AppName): $($_.RemoteHead)" }) -join "`n")
    throw (
        "COMMIT PIN MISMATCH: -Commit $wanted matches no deployed app's remote head.`n`n" +
        "Remote heads resolved for this run:`n$listing`n`n" +
        "Another chat almost certainly pushed to main between your plan run and now, " +
        "so continuing would ship their commits under your deploy. Nothing has been " +
        "changed on the server.`n`n" +
        "Re-read what is on main (git ls-remote origin main), confirm you still want " +
        "that code, then re-run with the -Commit value it reports."
    )
}

function Assert-AppRepoIntegrity($GitTarget) {
    # The deploy trigger further down is `HeadBefore -ne RemoteHead`, read from the
    # app's on-disk git state. That is only a meaningful signal while THIS script is
    # the only thing that ever moves HEAD.
    #
    # It wasn't. Until 2026-07-15 the staging CI job
    # (jarz_pos/.github/workflows/backend-tests.yml) synced the branch under test with
    # `docker cp . <backend>:/home/frappe/frappe-bench/apps/jarz_pos/`. That container
    # path IS the live erp_apps volume, and `docker cp .` copies the runner's whole
    # checkout — `.git` included. So CI silently advanced on-disk HEAD to the tip of
    # main without ever pulling: every subsequent deploy computed PendingUpdate=false
    # and skipped pip/migrate/cache-clear/restart while reporting success. Because
    # gunicorn runs with --preload (the app is imported in the master and workers fork
    # from it), the new code sat on disk and was NOT being served until a restart.
    # Disk looked deployed, CI was green, and the running code was two commits stale.
    #
    # CI no longer copies .git. This guard is the regression detector: it fails the
    # deploy loudly if the live repo ever again looks like a CI checkout rather than a
    # deploy clone. A hard failure here is always preferable to the silent false-green.
    $fingerprints = @()

    $isShallow = (Invoke-Remote "sudo test -f $($GitTarget.AppPath)/.git/shallow && echo yes || echo no" -IgnoreExitCode).Trim()
    if ($isShallow -eq 'yes') {
        $fingerprints += 'shallow clone (.git/shallow present) — deploys clone with full history; actions/checkout uses fetch-depth 1'
    }

    $extraHeader = (Invoke-Remote "sudo git -c safe.directory=$($GitTarget.AppPath) -C $($GitTarget.AppPath) config --get-regexp '^http\..*\.extraheader' || true" -IgnoreExitCode).Trim()
    if ($extraHeader) {
        $fingerprints += 'git config carries an actions/checkout AUTHORIZATION extraheader — a CI token was written into the live volume'
    }

    # -uno: tracked files only. CI's restore intentionally leaves untracked leftovers
    # rather than risk a version-dependent `git clean -d` against the live volume, so
    # untracked files must not fail this guard. They are NOT entirely inert, though —
    # an untracked leftover blocks the pull outright once a later commit adds a tracked
    # file at the same path. The pull step handles that case by removing only the
    # colliding paths; see the comment there. A MODIFIED TRACKED file is the signal
    # this guard exists for: it means the deployed code on disk is not the deployed
    # commit, and a `git pull` below would fail anyway.
    #
    # --no-optional-locks is load-bearing, not a micro-optimisation: plain `git status`
    # REFRESHES .git/index as a side effect, and we run it under sudo, so it would
    # rewrite the index as root:root on every deploy. CI then execs git as `frappe`
    # (uid 1000) and its restore step would fail on the unwritable index — this guard
    # would quietly break the very CI job whose regressions it exists to catch.
    # GIT_OPTIONAL_LOCKS=0 makes status skip that write and stay genuinely read-only.
    $dirty = (Invoke-Remote "sudo git --no-optional-locks -c safe.directory=$($GitTarget.AppPath) -C $($GitTarget.AppPath) status --porcelain -uno" -IgnoreExitCode).Trim()
    if ($dirty) {
        $fingerprints += "tracked files differ from the deployed commit (a CI run left code behind, or someone edited the server by hand):`n$dirty"
    }

    if ($fingerprints.Count -eq 0) {
        return
    }

    $detail = ($fingerprints | ForEach-Object { "  - $_" }) -join "`n"
    throw @"
$($GitTarget.AppName) at $($GitTarget.AppPath) is not a clean deploy clone:
$detail

Something other than this script is writing to the live app volume, which makes the
'already at target commit' fast-path unsafe (see the 2026-07-15 false-green above).
Refusing to deploy rather than report a green over a stale runtime.

To repair the repo in place — run as the 'ubuntu' account, the only one with sudo
(the CI runner deliberately has none). All code still comes from GitHub; nothing here
hand-edits an application file:
  ssh -i <key> ubuntu@$($config.ServerIp)
  APP=$($GitTarget.AppPath)
  # Drop the CI token and actions/checkout's leftovers, restore full history.
  sudo git -c safe.directory=`$APP -C `$APP config --unset-all 'http.https://github.com/.extraheader' || true
  sudo git -c safe.directory=`$APP -C `$APP config --unset core.worktree || true
  sudo git -c safe.directory=`$APP -C `$APP config --unset gc.auto || true
  sudo git -c safe.directory=`$APP -C `$APP checkout -- .
  sudo GIT_SSH_COMMAND='$gitSshCommand' git -c safe.directory=`$APP -C `$APP fetch --unshallow $($GitTarget.RemoteName) || true
  # Re-own to uid 1000. This is REQUIRED, not cosmetic: the CI runner is uid 1001
  # (github-runner) and stamped that uid on every file it copied, but the backend
  # container execs as 'frappe' = uid 1000 = host 'ubuntu'. Until this runs, CI's
  # non-root sync cannot write here at all. hrms/woo are already 1000:1000 — match them.
  sudo chown -R ubuntu:ubuntu `$APP
Then re-run this deploy.
"@
}

function Test-AppRequiresEditableReinstall($GitTarget) {
    if ($ForceReinstallApps) {
        return $true
    }

    if (-not $GitTarget.Changed) {
        return $false
    }

    $metadataDiff = Invoke-Remote "sudo git -c safe.directory=$($GitTarget.AppPath) -C $($GitTarget.AppPath) diff --name-only $($GitTarget.HeadBefore) $($GitTarget.HeadAfter) -- pyproject.toml setup.py setup.cfg requirements.txt requirements" -IgnoreExitCode
    return -not [string]::IsNullOrWhiteSpace($metadataDiff)
}

# Paths whose contents define the SITE SCHEMA rather than its behaviour. A commit
# touching any of them needs `bench migrate` before the code that reads the new
# field runs, and needs the post-migrate verification below to prove the field
# actually landed. Reported so the operator can see WHY a migrate was mandatory.
#
# git pathspecs, not shell globs: `*` here matches across `/` as well, so
# '*/doctype/*.json' covers jarz_pos/doctype/<folder>/<folder>.json at any depth.
$schemaPathspecs = @(
    "'*/doctype/*.json'"      # DocType definitions - new doctypes, new fields
    "'*/fixtures/*.json'"     # Custom Field / Property Setter fixtures
    "'*patches.txt'"          # the patch registry migrate walks
    "'*/patches/*'"           # patch bodies (data migrations)
    "'*/custom/*.json'"       # bench-exported customisations
) -join ' '

function Test-AppHasSchemaChanges($GitTarget) {
    if (-not $GitTarget.Changed) {
        return $false
    }

    $schemaDiff = Invoke-Remote "sudo git -c safe.directory=$($GitTarget.AppPath) -C $($GitTarget.AppPath) diff --name-only $($GitTarget.HeadBefore) $($GitTarget.HeadAfter) -- $schemaPathspecs" -IgnoreExitCode
    return -not [string]::IsNullOrWhiteSpace($schemaDiff)
}

function Install-EditableApps {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$AppNames,

        [Parameter(Mandatory = $true)]
        [hashtable]$ContainersByService
    )

    if (-not $AppNames -or $AppNames.Count -eq 0) {
        return
    }

    # Install into every DISTINCT virtualenv, discovered rather than assumed.
    #
    # Whether the four service containers share one venv is NOT a property of
    # this stack - it differs per server:
    #   staging     /home/frappe/frappe-bench/env is one directory seen by all
    #               four containers (same device+inode from each).
    #   production  `env` is baked into each container's own image layer. Only
    #               apps/, sites/ and logs/ are named volumes; env is not.
    #
    # So "install once in backend" is right on staging and silently wrong on
    # production, which is exactly how it failed on 2026-08-27: pypdfium2 landed
    # in erp-backend-1 alone, and the first PDF a manager uploaded came back
    # "Render Status: Failed - no PDF renderer installed", because the render job
    # runs on queue-long.
    #
    # Equally, looping blindly over all four re-installs into the SAME directory
    # on staging, which is how the earlier version tripped over its own
    # dist-info:
    #     OSError: [Errno 2] No such file or directory: '.../jarz_pos-0.0.1.dist-info/'
    #
    # Both failure modes disappear once we ask the server which venvs are
    # actually distinct, so neither environment is a special case.
    #
    # `2>&1` is appended so the REMOTE shell merges the streams before ssh
    # writes them. Without it pip's routine warnings arrive on ssh's stderr,
    # Windows PowerShell 5.1 wraps each line as a NativeCommandError, and
    # $ErrorActionPreference='Stop' kills a deploy whose pip run succeeded.
    # Exit codes still propagate, so a real failure still throws.
    #
    # pip output is intentionally NOT sent to /dev/null: a failed dependency
    # install must surface in the deploy log and fail the deploy, never
    # silently skip and break the feature at runtime.
    # Deliberately free of quote characters: this string is wrapped in single
    # quotes for the remote shell and lives inside a double-quoted PowerShell
    # string, so any quote inside it has to survive two levels of escaping.
    # Printing two integers separated by a space avoids the problem entirely.
    $sitePackagesProbe = "/home/frappe/frappe-bench/env/bin/python -c " +
        "'import site,os;st=os.stat(site.getsitepackages()[0]);print(st.st_dev,st.st_ino)'"

    $targets = [ordered]@{}
    foreach ($serviceName in $serviceNames) {
        $container = $ContainersByService[$serviceName]
        if ([string]::IsNullOrWhiteSpace($container)) { continue }
        $venvId = (Invoke-Remote "docker exec $container $sitePackagesProbe 2>&1" -IgnoreExitCode).Trim()
        if ([string]::IsNullOrWhiteSpace($venvId) -or $venvId -notmatch '^\d+\s+\d+$') {
            # Could not identify it - install here rather than skip. A wasted
            # pip run costs seconds; a skipped one costs a broken feature.
            $venvId = "unknown-$container"
        }
        if (-not $targets.Contains($venvId)) {
            $targets[$venvId] = $container
        }
    }

    if ($targets.Count -eq 0) {
        throw "Install-EditableApps: no service containers resolved; cannot install $($AppNames -join ', ')."
    }
    Write-Info "[pip] $($targets.Count) distinct virtualenv(s) across $($serviceNames.Count) services"

    foreach ($venvId in $targets.Keys) {
        $container = $targets[$venvId]
        foreach ($appName in $AppNames) {
            Write-Info "[pip] installing $appName (editable) in $container ..."
            Invoke-Remote ("docker exec -u root $container " +
                "/home/frappe/frappe-bench/env/bin/pip install -e " +
                "/home/frappe/frappe-bench/apps/$appName 2>&1") | Out-Null
        }
    }

    # Prove the DEPENDENCIES landed, not just the app.
    #
    # The previous version verified `import <app>` in every container and passed
    # on production while pypdfium2 was missing from three of them - because an
    # editable jarz_pos resolves through the shared apps/ volume regardless of
    # which venv ran pip. Importing the app therefore proves nothing about the
    # thing the reinstall exists to deliver. Read the app's declared runtime
    # dependencies and import those instead.
    foreach ($appName in $AppNames) {
        $modules = Get-AppDependencyModules -AppName $appName
        if (-not $modules -or $modules.Count -eq 0) { continue }
        foreach ($serviceName in $serviceNames) {
            $container = $ContainersByService[$serviceName]
            if ([string]::IsNullOrWhiteSpace($container)) { continue }
            $importList = ($modules -join ',')
            $probe = "docker exec $container /home/frappe/frappe-bench/env/bin/python -c 'import $importList' 2>&1"
            $result = Invoke-Remote $probe -IgnoreExitCode
            if ($LASTEXITCODE -ne 0) {
                throw ("Dependency check FAILED in $container for ${appName}: could not import $importList`n$result`n" +
                       'The editable install did not reach this container''s virtualenv.')
            }
        }
        Write-Info "[pip] $appName dependencies importable in all services: $($modules -join ', ')"
    }
    Write-Info "Editable reinstall complete: $($AppNames -join ', ')"
}

function Get-AppDependencyModules {
    param([Parameter(Mandatory = $true)][string]$AppName)

    # Third-party runtime deps declared in the app's requirements.txt, mapped to
    # the module name you actually import. Only names that differ need an entry;
    # anything else is assumed to import under its own (normalised) name.
    $moduleAliases = @{
        'firebase-admin' = 'firebase_admin'
        'sentry-sdk'     = 'sentry_sdk'
        'pywebpush'      = 'pywebpush'
    }

    # HOST path, not the container path. Invoke-Remote runs on the server's own
    # shell, where the apps volume lives at $remoteAppsDir — the in-container
    # /home/frappe/frappe-bench/apps/... simply does not exist there, so reading
    # it returns empty and the whole dependency check skips in silence. Which is
    # precisely the shape of the bug this check was added to catch.
    $reqPath = "$remoteAppsDir/$AppName/requirements.txt"
    $raw = Invoke-Remote "sudo test -f $reqPath && sudo cat $reqPath || true" -IgnoreExitCode
    if ([string]::IsNullOrWhiteSpace($raw)) {
        Write-Warn "[pip] $AppName declares no requirements.txt at $reqPath - dependency check skipped."
        return @()
    }

    $modules = @()
    foreach ($line in ($raw -split "`r?`n")) {
        $text = $line.Trim()
        if (-not $text -or $text.StartsWith('#')) { continue }
        $pkg = ($text -split '[<>=!~\[;]')[0].Trim()
        if (-not $pkg) { continue }
        if ($moduleAliases.ContainsKey($pkg)) { $modules += $moduleAliases[$pkg] }
        else { $modules += ($pkg -replace '-', '_') }
    }
    return @($modules | Select-Object -Unique)
}

# ── First-install bootstrap ──────────────────────────────────────────────────
# Until 2026-08-05 this script had no `bench install-app` anywhere: the only
# --site calls were backup, migrate and clear-cache. `bench migrate` does NOT
# install an app that is absent from the site, so a newly added app was pulled
# and pip-installed and then silently did nothing — no DocTypes, no fixtures.
# jarz_observability is the standing example: present in the bench, in zero
# deploy scripts, absent from apps.txt, and it has never deployed.
#
# Worse, Resolve-GitTarget hard-throws on a missing clone, so merely naming a new
# app in $deployedApps broke EVERY backend deploy, including POS hotfixes. The
# bootstrap below therefore runs before the Resolve-GitTarget loop.
#
# Every step is guarded by an existence check, so this is a no-op on a healthy
# server and safe to run on every deploy.

function Test-AppCloned([string]$AppName) {
    $appPath = "$remoteAppsDir/$AppName"
    # sudo is required: /var/lib/docker/volumes is root-only, so an unprivileged
    # `test -d` cannot traverse it and reports every app as missing. That sends
    # healthy servers down the Ensure-AppCloned path, where `git clone` into the
    # existing non-empty directory exits non-zero and kills the deploy before it
    # reaches the pull. Every other volume access in this script uses sudo.
    $probe = Invoke-Remote "sudo test -d '$appPath/.git' && echo yes || echo no" -IgnoreExitCode
    return ($probe.Trim() -eq 'yes')
}

function Get-SiteInstalledApps([string]$BackendContainer) {
    $output = Invoke-Remote "docker exec $BackendContainer bench --site frontend list-apps" -IgnoreExitCode
    return @(
        $output -split "`r?`n" |
            ForEach-Object { ($_ -split '\s+')[0] } |
            Where-Object { $_ }
    )
}

function Ensure-AppCloned([string]$AppName) {
    $appPath = "$remoteAppsDir/$AppName"

    if (Test-AppCloned $AppName) {
        # Ownership is re-asserted on EVERY run, not just after a fresh clone.
        # `sudo git clone` produces root:root, and if anything interrupts the
        # bootstrap between the clone and the chown the app is left unusable —
        # the containers exec as uid 1000 (`ubuntu` on the host) and cannot write
        # it. Re-running would then skip the chown forever, because the clone now
        # exists. It is a cheap no-op when already correct.
        Invoke-Remote "sudo chown -R ubuntu:ubuntu $appPath" | Out-Null
        return $false
    }

    $repoUrl = $appRepos[$AppName]
    if (-not $repoUrl) {
        throw ("App '$AppName' is missing at $remoteAppsDir/$AppName and has no entry in " +
               "`$appRepos. Register its clone URL before adding it to `$deployedApps.")
    }

    Write-Step "Bootstrapping $AppName - cloning (first install)..."
    # --quiet is required, not cosmetic. git writes "Cloning into '...'" and its
    # progress meter to STDERR, and Invoke-Remote merges stderr with 2>&1. Under
    # Windows PowerShell 5.1 a native command's stderr becomes NativeCommandError
    # records, which $ErrorActionPreference='Stop' treats as fatal — so a
    # perfectly successful clone aborted the deploy mid-bootstrap, leaving the
    # repo on disk as root:root with no chown and no install.
    #
    # Full clone, never --depth: Assert-AppRepoIntegrity rejects shallow clones.
    Invoke-Remote "sudo GIT_SSH_COMMAND='$(Get-GitSshCommand $AppName)' git clone --quiet $repoUrl $appPath" | Out-Null
    Invoke-Remote "sudo chown -R ubuntu:ubuntu $appPath" | Out-Null
    Write-Info "$AppName cloned"
    return $true
}

function Add-AppToBenchAppsTxt([string]$AppName, [string]$BackendContainer) {
    # bench only sees apps listed in sites/apps.txt. `bench get-app` maintains it;
    # a hand clone does not. Missing this line is precisely why an app can sit in
    # the bench forever without ever installing.
    $appsTxt = '/home/frappe/frappe-bench/sites/apps.txt'
    $inner = "grep -qxF '$AppName' $appsTxt || echo '$AppName' >> $appsTxt"
    $cmd = "docker exec -u root $BackendContainer bash -lc " + (ConvertTo-BashLiteral $inner)
    Invoke-Remote $cmd | Out-Null
}

# ── BOOTSTRAP-NOTES ──────────────────────────────────────────────────────────
# State of the jarz_courier first install as of 2026-08-05, and the order the
# steps must succeed in. On staging it is cloned at
# /var/lib/docker/volumes/erp_apps/_data/jarz_courier (uid 1000, full clone) but
# NOT yet pip-installed, so `bench install-app` still fails with
# ModuleNotFoundError. It has been removed from sites/apps.txt again — leaving a
# name there that Python cannot import makes `bench list-apps` print a traceback
# to stderr, which this script's Invoke-Remote turns into a fatal
# NativeCommandError and takes every deploy down with it.
#
# Remaining step, to run once and confirm before re-adding jarz_courier to
# $deployedApps:
#
#   docker exec -u root <backend> /home/frappe/frappe-bench/env/bin/pip \
#       install -e /home/frappe/frappe-bench/apps/jarz_courier
#   docker exec <backend> /home/frappe/frappe-bench/env/bin/python \
#       -c "import jarz_courier"      # must succeed before going further
#
# Then re-add it to $deployedApps and deploy: the bootstrap re-adds apps.txt,
# installs into all four service envs and runs `bench install-app`.
#
# Order is load-bearing throughout: clone -> chown -> pip install -> apps.txt ->
# install-app. Every earlier attempt failed by reaching a later step with an
# earlier one incomplete.
function Invoke-AppBootstrap {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$AppNames,

        [Parameter(Mandatory = $true)]
        [string]$BackendContainer,

        [Parameter(Mandatory = $true)]
        [hashtable]$ContainersByService,

        [switch]$ReportOnly
    )

    $missingClones = @($AppNames | Where-Object { -not (Test-AppCloned $_) })
    $installedApps = Get-SiteInstalledApps $BackendContainer
    # Checked for EVERY app on every deploy, not just freshly cloned ones: an app
    # can be on disk and pip-installed yet still absent from the site.
    $missingOnSite = @($AppNames | Where-Object { $installedApps -notcontains $_ })

    if ($ReportOnly) {
        foreach ($appName in $missingClones) {
            Write-Warn "$appName - would CLONE (not present on server)"
        }
        foreach ($appName in $missingOnSite) {
            Write-Warn "$appName - would INSTALL on site frontend"
        }
        if (-not $missingClones -and -not $missingOnSite) {
            Write-Info 'Bootstrap: all apps cloned and installed on site'
        }
        return
    }

    if (-not $missingClones -and -not $missingOnSite) {
        return
    }

    foreach ($appName in $AppNames) {
        [void](Ensure-AppCloned $appName)
    }

    # Prepare EVERY app that is not yet on the site, not just the ones cloned in
    # THIS run.
    #
    # Keying off "did I just clone it" assumes the bootstrap always completes,
    # and it does not: an interrupted run leaves the repo on disk, so the next
    # run sees it as already-cloned, skips apps.txt and the editable install, and
    # then `bench install-app` dies with
    #     ModuleNotFoundError: No module named '<app>'
    # because the package was never put on the Python path. Each step is
    # individually guarded, so redoing them is a cheap no-op.
    $needsPrep = @($missingOnSite)
    if ($needsPrep.Count -gt 0) {
        foreach ($appName in $needsPrep) {
            Add-AppToBenchAppsTxt $appName $BackendContainer
        }
        Write-Step "Installing into the Python env: $($needsPrep -join ', ')"
        # Deliberately NOT Install-EditableApps here. That function builds one
        # `bash -lc` script using `set -euo pipefail` and backgrounded jobs, and
        # it fails on this server with "bash: line 1: set: pipefail" — it only
        # ever fires when pyproject/requirements actually change, so that path
        # has evidently never run. Fixing it is its own change with its own
        # verification; the bootstrap must not depend on it.
        #
        # One plain docker exec per container instead: slower, but each has its
        # own exit code and its own error, and pip is already idempotent.
        foreach ($appName in $needsPrep) {
            foreach ($serviceName in $serviceNames) {
                $container = $ContainersByService[$serviceName]
                # `2>&1` is appended so the REMOTE shell merges the streams before
                # ssh ever writes them. Without it pip's routine warnings (e.g.
                # "Ignoring invalid distribution ...") arrive on ssh's stderr,
                # Windows PowerShell 5.1 wraps each line as a NativeCommandError,
                # and $ErrorActionPreference='Stop' kills the deploy on a pip run
                # that actually succeeded — leaving the app installed in the env
                # but never installed on the site. Exit codes still propagate, so
                # a real failure is still caught.
                Invoke-Remote ("docker exec -u root $container " +
                    "/home/frappe/frappe-bench/env/bin/pip install -q -e " +
                    "/home/frappe/frappe-bench/apps/$appName 2>&1") | Out-Null
            }
            Write-Info "$appName installed into all service envs"
        }
    }

    foreach ($appName in $AppNames) {
        if ($installedApps -contains $appName) {
            continue
        }
        Write-Step "Installing $appName on site frontend (first install)..."
        # Clear the cached app -> module map first. install-app syncs DocTypes from
        # frappe.local.app_modules, which comes from Redis ("app_modules") and on a
        # live server predates the new app: the Module Def gets created, zero
        # DocTypes sync, and after_install dies (jarz_social on staging, 2026-10-21).
        Invoke-Remote "docker exec $BackendContainer bench --site frontend clear-cache" | Out-Null
        Invoke-Remote "docker exec $BackendContainer bench --site frontend install-app $appName" | Out-Null
        Write-Info "$appName installed on site"
    }
}

# ── jarz_social opt-in ───────────────────────────────────────────────────────
# jarz_social is a private repo that the servers cannot read until the owner
# registers a deploy key for it. Naming it in $deployedApps would therefore make
# EVERY backend deploy (POS hotfixes included) abort at the clone -- the
# 2026-08-05 jarz_courier incident. So it joins a run only when:
#   * -SocialCommit is given (explicit request, pinned), or
#   * it is already cloned on that server (keeps following main like hrms).
# Everything else about it (clone, pip -e, apps.txt, install-app, pull, migrate,
# restart, head report) rides the generic per-app machinery above.

function Assert-SocialRepoReadable {
    # Fails up front, before the backup / clone / pull, with the exact one-time
    # setup the owner must do. Read-only: one `git ls-remote`. Returns the remote
    # head SHA of main so -SocialCommit can be enforced before anything is cloned.
    $keyPath = $appSshKeys[$socialApp]
    $repoUrl = $appRepos[$socialApp]

    $hasKey = (Invoke-Remote "test -f $keyPath && echo yes || echo no" -IgnoreExitCode).Trim()
    $out = ''
    $ok = $false
    if ($hasKey -eq 'yes') {
        $out = Invoke-Remote "GIT_SSH_COMMAND='$(Get-GitSshCommand $socialApp) -o BatchMode=yes' git ls-remote $repoUrl refs/heads/main 2>&1" -IgnoreExitCode
        $ok = ($out -match '(?m)^[0-9a-f]{40}\s+refs/heads/main')
    }

    if (-not $ok) {
        $why = if ($hasKey -ne 'yes') { "the deploy key $keyPath does not exist on $($config.ServerIp)" } else { "git ls-remote $repoUrl failed:`n$out" }
        throw (
            "jarz_social is requested but this server cannot read the private repo: $why`n`n" +
            "One-time owner setup (nothing in this script creates keys or edits server config), per server:`n" +
            "  1. ssh -i <pem> ubuntu@$($config.ServerIp)`n" +
            "  2. ssh-keygen -t ed25519 -N '' -C 'jarz_social-deploy-$Environment' -f $keyPath`n" +
            "  3. cat $keyPath.pub   (public half only - never paste the private key anywhere)`n" +
            "  4. GitHub > poparab/jarz_social > Settings > Deploy keys > Add deploy key:`n" +
            "     title 'erp-$Environment', paste the public key, leave 'Allow write access' UNTICKED.`n" +
            "     (GitHub refuses one deploy key on two repos, so the default id_ed25519 cannot be reused.)`n" +
            "  5. Verify: GIT_SSH_COMMAND='ssh -i $keyPath -o IdentitiesOnly=yes' git ls-remote $repoUrl refs/heads/main`n" +
            "Nothing has been changed on the server by this run."
        )
    }

    $head = (($out -split "`r?`n" | Where-Object { $_ -match 'refs/heads/main' } | Select-Object -First 1) -split '\s+')[0]
    if ($SocialCommit) {
        $wanted = $SocialCommit.Trim().ToLowerInvariant()
        if ($wanted -notmatch '^[0-9a-f]{7,40}$') {
            throw "-SocialCommit must be a hex git SHA of 7-40 characters; got '$SocialCommit'."
        }
        if (-not $head.StartsWith($wanted)) {
            throw (
                "SOCIAL COMMIT PIN MISMATCH: -SocialCommit $wanted does not match jarz_social's remote head $head.`n" +
                "Someone pushed to poparab/jarz_social main since the cut was recorded. Nothing has been " +
                "changed on the server. Re-check the commit, then re-run with the -SocialCommit value you want."
            )
        }
        Write-Info "-SocialCommit $wanted confirmed: jarz_social remote head is $head"
    }
    return $head
}

function Get-RemoteHttpCode {
    $output = ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i $SshKeyPath $sshTarget "curl -s -o /dev/null -w '%{http_code}' https://$($config.Domain) 2>/dev/null || echo 000" 2>$null
    return (($output -join "`n").Trim() -split "`r?`n")[-1]
}

Write-Host ''
Write-Info "============================================"
Write-Info "  Deploying to $($Environment.ToUpperInvariant()) ($($config.Domain))"
Write-Info "============================================"
Write-Host ''

if ($Environment -eq 'production' -and -not $Yes -and -not $PlanOnly) {
    Write-Warn 'You are about to deploy to PRODUCTION.'
    Write-Warn "Server: $($config.ServerIp) ($($config.Domain))"
    $confirmation = Read-Host 'Type yes to continue'
    if ($confirmation -ne 'yes') {
        Write-Info 'Deployment cancelled.'
        exit 0
    }
    Write-Host ''
}

Write-Step "Verifying SSH connection to $($config.ServerIp)..."
$null = Invoke-Remote 'echo ok'
Write-Info 'SSH connected'
Write-Host ''

$backendContainer = Resolve-ContainerName 'backend'
$frontendContainer = Resolve-ContainerName 'frontend'
$serviceContainers = @{}
foreach ($serviceName in $serviceNames) {
    $serviceContainers[$serviceName] = Resolve-ContainerName $serviceName
}

Write-Info "Backend container: $backendContainer"
Write-Info "Frontend container: $frontendContainer"
Write-Host ''

# Decide whether jarz_social is part of this run, and prove the server can read its
# private repo BEFORE anything is cloned, backed up or pulled.
$socialPlannedInstall = $false
$socialFreshInstall = $false
$socialTargetHead = $null
$socialCloned = Test-AppCloned $socialApp
$includeSocial = [bool]$SocialCommit -or $socialCloned
if ($includeSocial) {
    Write-Step 'Checking jarz_social repo access...'
    $socialTargetHead = Assert-SocialRepoReadable
    Write-Info "jarz_social is readable from the server; remote main is $socialTargetHead"
    $config.CustomApps = @($deployedApps) + $socialApp
    $socialSiteApps = Get-SiteInstalledApps $backendContainer
    $socialFreshInstall = (-not $socialCloned) -or ($socialSiteApps -notcontains $socialApp)
    $socialPlannedInstall = $socialFreshInstall
    Write-Host ''
}
else {
    Write-Info 'jarz_social: not installed on this server and not requested (pass -SocialCommit <sha> to install/pin it)'
    Write-Host ''
}

# MUST run before the Resolve-GitTarget loop below: that loop calls `git rev-parse`
# on every app path and hard-throws if the clone is absent, which would break this
# deploy and every other one until the app was cloned by hand.
Write-Step 'Checking app bootstrap state...'
Invoke-AppBootstrap `
    -AppNames $config.CustomApps `
    -BackendContainer $backendContainer `
    -ContainersByService $serviceContainers `
    -ReportOnly:$PlanOnly
Write-Host ''

$gitTargets = foreach ($appName in $config.CustomApps) {
    # Under -PlanOnly the bootstrap above only REPORTS what it would do, so an
    # app awaiting first install is still absent from disk. Resolve-GitTarget
    # runs `git rev-parse` against its path and hard-throws on a missing
    # directory, which crashed the plan immediately after correctly announcing
    # "would CLONE". A plan must never fail on the thing it just planned.
    #
    # Skipped only in report mode: a real deploy has already cloned the app by
    # the time control reaches here, so it resolves normally and keeps the full
    # integrity check.
    if ($PlanOnly -and -not (Test-AppCloned $appName)) {
        Write-Info "$appName - skipping git plan; pending first-install bootstrap"
        continue
    }

    $gitTarget = Resolve-GitTarget $appName
    Assert-AppRepoIntegrity $gitTarget
    $remoteUrl = Convert-GitHubRemoteToSsh $gitTarget
    $gitTarget.RemoteUrl = $remoteUrl
    $gitTarget.RemoteHead = Get-RemoteBranchHead $gitTarget
    if ($pinnedAppHeads.ContainsKey($appName)) {
        $pin = $pinnedAppHeads[$appName]
        if ($gitTarget.RemoteHead -ne $pin) {
            Write-Info "$appName pinned at $pin (branch tip $($gitTarget.RemoteHead) not taken)"
        }
        $gitTarget.RemoteHead = $pin
        $gitTarget.Pinned = $true
    }
    $gitTarget.PendingUpdate = $gitTarget.HeadBefore -ne $gitTarget.RemoteHead
    $gitTarget
}

Assert-RequestedCommit $gitTargets $Commit

$appsNeedingUpdate = @($gitTargets | Where-Object { $_.PendingUpdate })
$deployRequired = $appsNeedingUpdate.Count -gt 0

if ($PlanOnly) {
    Write-Step 'Backend deploy plan'
    foreach ($gitTarget in $gitTargets) {
        $status = if ($gitTarget.PendingUpdate) { 'update-required' } else { 'current' }
        Write-Info "$($gitTarget.AppName): $status"
        Write-Host "        current: $($gitTarget.HeadBefore)"
        Write-Host "        target : $($gitTarget.RemoteHead)"
    }
    if ($socialPlannedInstall -and -not ($gitTargets | Where-Object { $_.AppName -eq $socialApp })) {
        # Not on disk yet, so there is no git state to compare: show the first-install plan.
        Write-Info "${socialApp}: install-required (first install: clone, pip -e, apps.txt, install-app)"
        Write-Host "        current: (not installed)"
        Write-Host "        target : $socialTargetHead"
    }
    Write-Host ''
    $planUpdatedApps = @($appsNeedingUpdate | ForEach-Object { $_.AppName })
    if ($socialPlannedInstall -and $planUpdatedApps -notcontains $socialApp) { $planUpdatedApps += $socialApp }
    Write-Output "DEPLOY_REQUIRED=$(($deployRequired -or $socialPlannedInstall).ToString().ToLowerInvariant())"
    Write-Output "UPDATED_APPS=$($planUpdatedApps -join ',')"
    exit 0
}

# -SkipMigrate cannot be honoured on a deploy that actually ships something.
#
# The failure it invites is silent and delayed: the new code lands on disk and
# starts serving, the field it reads was never created, and every read of that
# field returns None until somebody notices in production days later. Nothing
# fails at deploy time, so the deploy that caused it is long out of view by the
# time the symptom appears.
#
# Refused HERE, before the backup and before the pull, so a refused run changes
# nothing on the server. Throwing after the pull would be worse than not
# checking: new code on disk with un-migrated schema is exactly the state this
# guard exists to prevent.
#
# The switch is kept rather than deleted because it stays meaningful for a
# no-op deploy (nothing to ship, nothing to migrate), and because deploy_remote
# forwards it. There is deliberately no override: "migrate anyway" is always
# available and always correct, so an escape hatch here could only ever be used
# to cause the bug above.
if ($SkipMigrate -and $deployRequired) {
    $pendingList = (@($appsNeedingUpdate | ForEach-Object { $_.AppName }) -join ', ')
    throw ("-SkipMigrate refused: this deploy updates $pendingList, and a deploy that " +
        "ships code must run 'bench migrate'. A skipped migration leaves new code " +
        "reading fields that were never created, and fails silently at read time " +
        "rather than at deploy time. Re-run without -SkipMigrate.")
}

if ($config.RequiresBackup -and -not $SkipBackup -and $deployRequired) {
    Write-Step 'Taking production backup before deployment...'
    $backupOutput = Invoke-Remote "docker exec $backendContainer bench --site frontend backup --with-files"
    if ($backupOutput) {
        $backupOutput -split "`r?`n" | Select-Object -Last 3 | ForEach-Object { Write-Host $_ }
    }
    Write-Info 'Backup complete'
    Write-Host ''
}
elseif ($config.RequiresBackup -and $deployRequired) {
    Write-Step 'Skipping production backup (--SkipBackup)'
    Write-Host ''
}

Write-Step 'Pulling latest code for custom apps...'
foreach ($gitTarget in $gitTargets) {
    Write-Info "Using remote URL: $($gitTarget.RemoteUrl)"
    if (-not $gitTarget.PendingUpdate) {
        Write-Info "$($gitTarget.AppName) already at target commit $($gitTarget.HeadBefore)"
        continue
    }

    # Clear CI's untracked leftovers before pulling, but ONLY where they collide.
    #
    # backend-tests.yml runs on the self-hosted staging-docker runner and syncs the
    # branch under test straight into this live volume, then restores with
    # `git checkout -- .` — which only restores TRACKED files. Anything new in the
    # tested commit survives as an untracked leftover. That is genuinely inert until a
    # release adds a tracked file at the same path: `git pull` then aborts with
    # "untracked working tree files would be overwritten by merge" and the deploy dies
    # at the pull. f851371 hit exactly this — its new tests/test_v16_query_compat.py
    # collided with the copy CI had already left behind. It recurs on any release that
    # adds a file, because CI tests that commit against this volume first.
    #
    # Delete only untracked paths the incoming commit ADDS. That is provably
    # convergent: the pull writes the authoritative version at that exact path a
    # second later. Deliberately not `git clean` — this is a live volume and a broad
    # clean could take out anything else living here. --exclude-standard is correct:
    # ignored files are overwritten by merge without complaint and never block a pull.
    Invoke-Remote "sudo GIT_SSH_COMMAND='$(Get-GitSshCommand $gitTarget.AppName)' git -c safe.directory=$($gitTarget.AppPath) -C $($gitTarget.AppPath) fetch --quiet $($gitTarget.RemoteName) $($gitTarget.BranchName)" | Out-Null

    $splitLines = { param($text) ($text -split "`r?`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ } }
    $addedPaths = & $splitLines (Invoke-Remote "sudo git -c safe.directory=$($gitTarget.AppPath) -C $($gitTarget.AppPath) diff --diff-filter=A --name-only HEAD $($gitTarget.RemoteHead)" -IgnoreExitCode)
    $untrackedPaths = & $splitLines (Invoke-Remote "sudo git -c safe.directory=$($gitTarget.AppPath) -C $($gitTarget.AppPath) ls-files --others --exclude-standard" -IgnoreExitCode)

    $collisions = @($addedPaths | Where-Object { $untrackedPaths -contains $_ })
    if ($collisions.Count -gt 0) {
        Write-Info "Removing $($collisions.Count) untracked file(s) colliding with paths added by the incoming commit (CI leftovers):"
        $collisions | ForEach-Object { Write-Info "  - $_" }
        $quotedPaths = ($collisions | ForEach-Object { "'$($gitTarget.AppPath)/$_'" }) -join ' '
        Invoke-Remote "sudo rm -f $quotedPaths" | Out-Null
    }

    # Fast-forward to the EXACT commit this run resolved and verified, not to
    # whatever the branch tip is right now.
    #
    # `git pull <remote> <branch>` re-resolves the tip at pull time, which
    # re-opens the very race -Commit exists to close: the pin is checked, a
    # peer chat pushes, and the pull silently takes their commit instead.
    # RemoteHead came from ls-remote earlier in this run and the fetch above
    # brought it down, so merging that SHA is deterministic.
    #
    # --ff-only is deliberate. A live app volume must never grow a merge
    # commit, and divergence here means something outside this script wrote to
    # the volume — which is exactly the CI-clobber class of bug that has
    # false-greened deploys before. Failing is correct, and it fails BEFORE
    # anything lands, so the abort leaves no half-deployed state.
    $gitBase = "sudo git -c safe.directory=$($gitTarget.AppPath) -C $($gitTarget.AppPath)"
    $movesBack = $false
    if ($gitTarget.Pinned) {
        # Behind or at the pin: fast-forward as usual. Ahead of it: move back (see $pinnedAppHeads).
        $direction = (Invoke-Remote "if $gitBase merge-base --is-ancestor HEAD $($gitTarget.RemoteHead); then echo FORWARD; elif $gitBase merge-base --is-ancestor $($gitTarget.RemoteHead) HEAD; then echo BACK; else echo DIVERGED; fi").Trim()
        if ($direction -eq 'DIVERGED') {
            throw "$($gitTarget.AppName) HEAD $($gitTarget.HeadBefore) and its pin $($gitTarget.RemoteHead) have diverged; refusing to move it."
        }
        $movesBack = $direction -eq 'BACK'
    }
    if ($movesBack) {
        Write-Info "Moving pinned $($gitTarget.AppName) back from $($gitTarget.HeadBefore) to $($gitTarget.RemoteHead)"
        # pip's editable reinstall and chown touch every file, leaving the index's stat
        # cache stale; reset --keep then calls clean files "not uptodate". Refresh it first.
        Invoke-Remote "$gitBase update-index -q --refresh" -IgnoreExitCode | Out-Null
        $pullOutput = Invoke-Remote "$gitBase reset --keep --quiet $($gitTarget.RemoteHead)"
    }
    else {
        Write-Info "Fast-forwarding $($gitTarget.AppName) to $($gitTarget.RemoteHead)"
        $pullOutput = Invoke-Remote "sudo GIT_SSH_COMMAND='$(Get-GitSshCommand $gitTarget.AppName)' git -c safe.directory=$($gitTarget.AppPath) -C $($gitTarget.AppPath) merge --ff-only --quiet $($gitTarget.RemoteHead)"
    }
    if ($pullOutput) {
        Write-Host $pullOutput
    }

    $gitTarget.HeadAfter = (Invoke-Remote "sudo git -c safe.directory=$($gitTarget.AppPath) -C $($gitTarget.AppPath) rev-parse HEAD").Trim()

    # Tripwire. The ff-only merge above targets an exact SHA, so this can only
    # fire if something else moved HEAD underneath the deploy — the class of
    # event that has silently false-greened deploys here before. Report what
    # actually landed rather than trusting the intent.
    if ($gitTarget.HeadAfter -ne $gitTarget.RemoteHead) {
        throw (
            "$($gitTarget.AppName) landed on $($gitTarget.HeadAfter) but this run " +
            "resolved and verified $($gitTarget.RemoteHead). Something outside this " +
            "script moved HEAD on the volume mid-deploy. The new code is on disk but " +
            "the running workers have NOT been restarted - treat the app as serving " +
            "the old code until you re-run this script with -ForceMigrate."
        )
    }

    $gitTarget.Changed = $gitTarget.HeadBefore -ne $gitTarget.HeadAfter
    $gitTarget.RequiresPipInstall = Test-AppRequiresEditableReinstall $gitTarget
    $gitTarget.SchemaChanged = Test-AppHasSchemaChanges $gitTarget
    Write-Info "$($gitTarget.AppName) updated to $($gitTarget.HeadAfter)"
    if ($gitTarget.SchemaChanged) {
        Write-Info "$($gitTarget.AppName) carries SCHEMA changes (doctype/fixture/patch) - migrate is mandatory"
    }

    # Normalise ownership to uid 1000 after every pull. The pull runs under sudo
    # (unavoidable — /var/lib/docker/volumes is only traversable by root), so every
    # file it rewrites lands as root:root. Nothing noticed while the deploy was the
    # only writer, but staging's CI execs as 'frappe' (uid 1000 = host 'ubuntu') and
    # cannot write root-owned files, so an un-normalised pull would break the test
    # gate on exactly the files a release just changed. The stray root-owned file on
    # the woo volume is a fossil of this. Idempotent, and cheap next to the pull.
    Invoke-Remote "sudo chown -R ubuntu:ubuntu $($gitTarget.AppPath)" | Out-Null

    if ($gitTarget.RequiresPipInstall) {
        Write-Info "$($gitTarget.AppName) queued for editable reinstall"
    }
}
Write-Host ''

$changedApps = @($gitTargets | Where-Object { $_.Changed })
$changedAppNames = @($changedApps | ForEach-Object { $_.AppName })

# -ForceReinstallApps has to open this gate as well as the inner one.
#
# It was only ever OR-ed in at the $appsNeedingInstall filter below, which sits
# INSIDE this else-branch — so with nothing pending, the branch never ran and
# the switch did nothing at all while reporting "Skipping reinstall ... Use
# -ForceReinstallApps to override". That is the one situation it exists for: a
# previous deploy pulled the commit but failed to install its dependency, so
# git is already at target and only the venv is wrong.
# A fresh jarz_social install lands during the bootstrap, before this point, so its
# pull is a no-op and $changedAppNames can be empty. The workers still must restart
# to import the new app (scheduler jobs, hooks) and migrate must sync it, so a fresh
# install opens this gate by itself.
if ($changedAppNames.Count -eq 0 -and -not $ForceMigrate -and -not $ForceReinstallApps -and -not $socialFreshInstall) {
    Write-Info 'No custom app commits changed on the target server. Skipping reinstall, asset relink, migrate, cache clear, and service restart.'
    Write-Host ''
}
else {
    if ($changedAppNames.Count -eq 0) {
        $why = @()
        if ($ForceMigrate) { $why += '-ForceMigrate' }
        if ($ForceReinstallApps) { $why += '-ForceReinstallApps' }
        if ($socialFreshInstall) { $why += 'jarz_social first install' }
        Write-Info ("No custom app commits changed, but $($why -join ' + ') was set: proceeding " +
                    '(e.g. a dependency or schema change already on the server but never installed/migrated).')
        Write-Host ''
    }
    Write-Step 'Installing custom apps in backend and workers...'
    # `-ForceReinstallApps` is OR-ed in here, not left to RequiresPipInstall
    # alone. That flag is set inside the pull block (line ~767), which is
    # skipped entirely when an app is "already at target commit" — so the one
    # situation the switch exists for could never reach it: a previous deploy
    # that pulled the code and then died before installing its new dependency.
    # That is exactly what happened on 2026-08-26, and the escape hatch was
    # inert. Honouring the switch unconditionally is the whole point of a
    # switch. pip -e is idempotent, so a redundant run costs time, not safety.
    $appsNeedingInstall = @($gitTargets |
        Where-Object { $_.RequiresPipInstall -or $ForceReinstallApps } |
        ForEach-Object { $_.AppName })
    if ($appsNeedingInstall.Count -gt 0) {
        Install-EditableApps -AppNames $appsNeedingInstall -ContainersByService $serviceContainers
        foreach ($serviceName in $serviceNames) {
            $containerName = $serviceContainers[$serviceName]
            Write-Info "Installed $($appsNeedingInstall -join ', ') in $containerName"
        }
    }
    else {
        Write-Info 'Skipping editable reinstall; no dependency metadata changes detected. Use -ForceReinstallApps to override.'
    }
    Write-Host ''

    if ($changedAppNames -contains 'jarz_pos') {
        Write-Step 'Linking jarz_pos desk assets...'
        foreach ($assetContainer in @($backendContainer, $frontendContainer)) {
            $null = Invoke-Remote "docker exec -u root $assetContainer bash -lc 'mkdir -p /home/frappe/frappe-bench/sites/assets && ln -sfn /home/frappe/frappe-bench/apps/jarz_pos/jarz_pos/public /home/frappe/frappe-bench/sites/assets/jarz_pos'"
        }
        Write-Info 'Desk asset links refreshed'
        Write-Host ''
    }

    if (-not $SkipMigrate) {
        Write-Step 'Running bench migrate...'
        # Surface the migrate output instead of discarding it. Data-migration
        # patches print their summaries to stdout, and sending them to $null made
        # them invisible to the operator -- hit for real on 2026-08-19 by
        # set_woo_invoice_is_pos, which backfills is_pos across hundreds of
        # submitted invoices. Invoke-Remote already folds stderr in and throws on
        # a non-zero exit, so this changes visibility only, not failure handling.
        $migrateOutput = Compress-MigrateProgress (Invoke-Remote "docker exec $backendContainer bench --site frontend migrate")
        if ($migrateOutput) {
            Write-Host '----- bench migrate output -----' -ForegroundColor DarkGray
            Write-Host $migrateOutput
            Write-Host '----- end bench migrate output -----' -ForegroundColor DarkGray
        }
        Write-Info 'Migration complete'

        # A green migrate is NOT evidence that a new field exists.
        #
        # Two Frappe mechanisms drop schema without failing: the fixture importer
        # skips a doc whose `modified` timestamp matches the stored one (so a
        # flag-only edit to custom_field.json does nothing unless `modified` is
        # bumped), and a `dt` absent from the Custom Field filter in
        # hooks.fixtures is never imported on any site at all. Both leave the
        # deploy green and the field missing, and the first symptom is an
        # endpoint reading None in production days later.
        #
        # verify_schema_landed asserts every field jarz_pos DECLARES against the
        # LIVE meta and columns, and exits non-zero when they disagree — turning
        # a silent, delayed data bug into a loud deploy failure. Read-only, so it
        # is safe on production and safe to run on every migrate rather than only
        # when the diff looked schema-shaped.
        $verifierModule = 'jarz_pos.scripts.verify_schema_landed'
        $verifierPath = "/home/frappe/frappe-bench/apps/jarz_pos/jarz_pos/scripts/verify_schema_landed.py"
        # Not piped straight into .Trim(): an empty or null reply (a dropped ssh
        # read) would throw there and fail a deploy over the *probe* rather than
        # over anything it found.
        $verifierProbe = Invoke-Remote "docker exec $backendContainer bash -lc 'test -f $verifierPath && echo yes || echo no'" -IgnoreExitCode
        $verifierPresent = if ($verifierProbe) { ([string]$verifierProbe).Trim() } else { '' }

        if ($verifierPresent -eq 'yes') {
            Write-Step 'Verifying the declared schema is live...'
            # Invoke-Remote throws on a non-zero exit, so a missing field fails
            # the deploy here rather than being discovered in production.
            $verifyOutput = Invoke-Remote "docker exec $backendContainer bench --site frontend execute $verifierModule.run"
            if ($verifyOutput) {
                $verifyOutput -split "`r?`n" |
                    Where-Object { $_ -match 'Schema verification|missing|unfixtured' } |
                    Select-Object -First 20 |
                    ForEach-Object { Write-Host $_ }
            }
            Write-Info 'Declared schema confirmed live'
        }
        else {
            # Only reachable on a server whose jarz_pos predates this verifier —
            # e.g. -ForceMigrate against an un-updated checkout. Warn rather than
            # fail: there is nothing to verify against, and refusing would block
            # the very deploy that installs it.
            Write-Warn "Schema verifier not present at $verifierPath; skipping post-migrate verification"
        }
    }
    else {
        # Unreachable on a deploy that ships anything: -SkipMigrate is refused at
        # pre-flight when $deployRequired. This branch covers the no-op case only.
        Write-Step 'Skipping migration (--SkipMigrate; nothing was deployed)'
    }
    Write-Host ''

    Write-Step 'Clearing cache and restarting services...'
    Invoke-Remote "docker exec $backendContainer bench --site frontend clear-cache" | Out-Null
    Invoke-Remote "cd $remoteDir && docker compose restart backend queue-short queue-long scheduler >/dev/null 2>&1 || docker-compose restart backend queue-short queue-long scheduler >/dev/null 2>&1" | Out-Null
    # Restart the frontend nginx AFTER the backend is back up so it re-resolves the
    # backend's (possibly new) Docker network IP. Without this, nginx keeps the old
    # upstream IP cached and every edge/API request returns 502 (connect refused)
    # until the frontend is manually restarted. See the 2026-07-11 prod incident.
    Invoke-Remote "cd $remoteDir && docker compose restart frontend >/dev/null 2>&1 || docker-compose restart frontend >/dev/null 2>&1" | Out-Null
    Write-Info 'Services restarted (incl. frontend nginx)'
    Write-Host ''
}

Write-Step 'Checking deployed commit heads...'
foreach ($gitTarget in $gitTargets) {
    $headCommit = (Invoke-Remote "sudo git -c safe.directory=$($gitTarget.AppPath) -C $($gitTarget.AppPath) rev-parse HEAD").Trim()
    Write-Info "$($gitTarget.AppName): $headCommit"
}
Write-Host ''

Write-Step 'Running health check...'
$httpCode = '000'
for ($attempt = 1; $attempt -le 3; $attempt++) {
    $httpCode = Get-RemoteHttpCode
    if ($httpCode -in @('200', '301', '302')) {
        break
    }

    if ($attempt -lt 3) {
        Write-Warn "Health check returned HTTP $httpCode on attempt $attempt. Retrying..."
        Start-Sleep -Seconds 5
    }
}

Write-Host ''
Write-Info '============================================'
if ($httpCode -in @('200', '301', '302')) {
    Write-Info 'Deployment completed successfully'
    Write-Info "URL: https://$($config.Domain)"
    Write-Info "HTTP Status: $httpCode"
}
else {
    Write-Warn "Site returned HTTP $httpCode after restart. Containers may still be warming up."
    $containerStatus = Invoke-Remote "docker ps --format 'table {{.Names}}`t{{.Status}}' | grep -E 'erp-(backend|queue-short|queue-long|scheduler)-1|erp_(backend|queue-short|queue-long|scheduler)_1'" -IgnoreExitCode
    if ($containerStatus) {
        Write-Host $containerStatus
    }
}
Write-Info '============================================'
Write-Host ''