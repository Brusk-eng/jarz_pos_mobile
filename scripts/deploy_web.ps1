param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('staging', 'production')]
    [string]$Environment,

    [switch]$PlanOnly,
    [switch]$ForceDeploy,
    [switch]$AllowDirty,
    [string]$SshKeyPath,

    # Which web app to ship. 'pos' (default) is the POS app served at /pos/ and behaves
    # exactly as before. 'studio' builds lib/main_studio.dart with --base-href /studio/
    # and serves it beside the POS app at /studio/ from the same pos-web container (same
    # origin as the API, so the session cookie works). Staging only for now.
    [ValidateSet('pos', 'studio')]
    [string]$App = 'pos',

    # Pin the deploy to a known commit; mirrors deploy_backend.ps1 -Commit so
    # "deploy commit X" means the same thing on both halves of a release.
    # Here it asserts the LOCAL checkout is at that commit, because this script
    # builds the working tree rather than pulling on the server. Several chats
    # share this checkout, so the HEAD you reasoned about and the HEAD that
    # gets stamped into release-metadata.json are not necessarily the same one.
    [string]$Commit
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$workspaceRoot = Split-Path -Parent $repoRoot
if (-not $SshKeyPath) {
    $SshKeyPath = Join-Path $workspaceRoot 'ERPNext-stg.pem'
}

$remoteWebDir = '/home/ubuntu/pos-web/web'
$remoteDownloadStore = '/home/ubuntu/pos-web/downloads'
$remoteServedDownloadDir = "$remoteWebDir/download"
$remoteMetaPath = "$remoteWebDir/release-metadata.json"
$localNginxConfigPath = Join-Path $repoRoot 'scripts\pos-web\nginx.conf'
$remoteNginxConfigPath = '/home/ubuntu/pos-web/nginx.conf'
# Tracked copies of the container's Dockerfile and compose file. Applied on staging only
# for now: production's compose differs in its Host() rule and keeps its server-side copy.
$localDockerfilePath = Join-Path $repoRoot 'scripts\pos-web\Dockerfile'
$localComposePath = Join-Path $repoRoot 'scripts\pos-web\docker-compose.yml'
$remoteDockerfilePath = '/home/ubuntu/pos-web/Dockerfile'
$remoteComposePath = '/home/ubuntu/pos-web/docker-compose.yml'
$remoteStudioDir = '/home/ubuntu/pos-web/studio-web'

if ($App -eq 'studio' -and $Environment -ne 'staging') {
    throw "-App studio is staging-only for now; refusing to deploy it to $Environment."
}

if (-not (Test-Path $SshKeyPath)) {
    throw "SSH key not found at $SshKeyPath"
}

if (-not (Test-Path $localNginxConfigPath)) {
    throw "POS web nginx config not found at $localNginxConfigPath"
}

$config = switch ($Environment) {
    'staging' {
        @{
            ServerIp = '13.36.219.136'
            PosUrl = 'https://erpstg.orderjarz.com/pos/'
        }
    }
    'production' {
        @{
            ServerIp = '13.36.132.13'
            PosUrl = 'https://erp.orderjarz.com/pos/'
        }
    }
}

if ($App -eq 'studio') {
    # Metadata, hash check, upload and health probe all work on $remoteWebDir and
    # $config.PosUrl, so pointing those at /studio/ reuses them unchanged.
    $remoteWebDir = $remoteStudioDir
    $remoteMetaPath = "$remoteWebDir/release-metadata.json"
    $config.PosUrl = $config.PosUrl -replace '/pos/$', '/studio/'
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

function Invoke-Git {
    param(
        [string[]]$Arguments,
        [switch]$IgnoreExitCode
    )

    $safeDirectory = $repoRoot -replace '\\', '/'
    $output = & git -c "safe.directory=$safeDirectory" -C $repoRoot @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0 -and -not $IgnoreExitCode) {
        throw "git -C $repoRoot $($Arguments -join ' ') failed ($exitCode)`n$($output -join "`n")"
    }

    return ($output -join "`n").TrimEnd()
}

function Test-WebRuntimeImpact([string[]]$Paths) {
    foreach ($path in $Paths) {
        if (
            $path.StartsWith('assets/') -or
            $path.StartsWith('lib/') -or
            $path.StartsWith('tool/') -or
            $path.StartsWith('web/') -or
            $path -eq 'scripts/pos-web/nginx.conf' -or
            $path -eq '.env.prod' -or
            $path -eq '.env.staging' -or
            $path -eq 'l10n.yaml' -or
            $path -eq 'pubspec.yaml' -or
            $path -eq 'pubspec.lock' -or
            $path -eq 'scripts/build_release.bat' -or
            $path -eq 'scripts/build_release.sh'
        ) {
            return $true
        }
    }

    return $false
}

function Get-RepoHead {
    return (Invoke-Git -Arguments @('rev-parse', 'HEAD')).Trim()
}

function Get-DirtyPaths {
    $output = Invoke-Git -Arguments @('status', '--porcelain')
    if ([string]::IsNullOrWhiteSpace($output)) {
        return @()
    }
    return @($output -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Get-RemoteReleaseMetadata {
    $raw = Invoke-Remote "test -f $remoteMetaPath && cat $remoteMetaPath" -IgnoreExitCode
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }

    try {
        return $raw | ConvertFrom-Json
    }
    catch {
        Write-Warn 'Remote web release metadata is not valid JSON; treating web as out of date.'
        return $null
    }
}

function Get-RemoteMainHash {
    return (Invoke-Remote "test -f $remoteWebDir/main.dart.js && sha256sum $remoteWebDir/main.dart.js | cut -d ' ' -f1" -IgnoreExitCode).Trim().ToLowerInvariant()
}

function Test-WebDeployRequired {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LocalHead,

        [Parameter(Mandatory = $true)]
        [string]$LocalNginxConfigHash,

        [Parameter(Mandatory = $false)]
        $RemoteMetadata
    )

    if ($ForceDeploy) {
        return @{
            Required = $true
            Reason = 'force-deploy'
        }
    }

    if (-not $RemoteMetadata -or -not $RemoteMetadata.commit_sha) {
        return @{
            Required = $true
            Reason = 'missing-remote-metadata'
        }
    }

    $remoteNginxConfigHash = "$($RemoteMetadata.pos_web_nginx_conf_sha256)".Trim().ToLowerInvariant()
    if (-not $remoteNginxConfigHash) {
        return @{
            Required = $true
            Reason = 'missing-remote-nginx-config-hash'
        }
    }

    if ($remoteNginxConfigHash -ne $LocalNginxConfigHash) {
        return @{
            Required = $true
            Reason = 'nginx-config-changed'
        }
    }

    $remoteCommit = "$($RemoteMetadata.commit_sha)".Trim()
    if ($remoteCommit -eq $LocalHead -and "$($RemoteMetadata.environment)" -eq $Environment) {
        return @{
            Required = $false
            Reason = 'same-commit-already-deployed'
        }
    }

    $null = Invoke-Git -Arguments @('cat-file', '-e', "$remoteCommit^{commit}") -IgnoreExitCode
    if ($LASTEXITCODE -ne 0) {
        return @{
            Required = $true
            Reason = 'remote-commit-not-present-locally'
        }
    }

    $diffOutput = Invoke-Git -Arguments @('diff', '--name-only', $remoteCommit, $LocalHead)
    $paths = @()
    if (-not [string]::IsNullOrWhiteSpace($diffOutput)) {
        $paths = @($diffOutput -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    }

    if (-not (Test-WebRuntimeImpact $paths)) {
        return @{
            Required = $false
            Reason = 'no-web-impacting-paths-since-last-web-deploy'
        }
    }

    return @{
        Required = $true
        Reason = 'web-impacting-paths-changed'
    }
}

Write-Host ''
Write-Info "============================================"
Write-Info "  Deploying Web to $($Environment.ToUpperInvariant())"
Write-Info "============================================"
Write-Host ''

$localHead = Get-RepoHead

# Enforce -Commit before the dirty check and before any build, so a mismatch
# costs nothing. Prefix-matched: callers quote the short SHA git log shows them.
if ($Commit) {
    $wantedCommit = $Commit.Trim().ToLowerInvariant()
    if ($wantedCommit -notmatch '^[0-9a-f]{7,40}$') {
        throw "-Commit must be a hex git SHA of 7-40 characters; got '$Commit'."
    }
    if (-not $localHead.ToLowerInvariant().StartsWith($wantedCommit)) {
        throw (
            "COMMIT PIN MISMATCH: -Commit $wantedCommit but this checkout is at $localHead.`n`n" +
            "Another chat has moved HEAD in this shared checkout, so the build would ship " +
            "code you have not reviewed, stamped with a commit you did not intend. Nothing " +
            "has been built or uploaded.`n`n" +
            "Confirm what is checked out (git log --oneline -1), then re-run with that SHA."
        )
    }
    Write-Info "-Commit $wantedCommit confirmed: local HEAD is $localHead"
}

# The build below compiles the WORKING TREE, but release-metadata.json is stamped
# with $localHead. Several Claude chats share this checkout, so a dirty tree means
# shipping another chat's half-finished code under a commit SHA that does not
# contain it - an artifact no one can trace back to a commit. Refuse by default.
$dirtyPaths = Get-DirtyPaths
if ($dirtyPaths.Count -gt 0) {
    $listing = ($dirtyPaths | Select-Object -First 20) -join "`n  "
    $summary = "Working tree is dirty ($($dirtyPaths.Count) path(s)):`n  $listing"
    if ($PlanOnly) {
        Write-Warn $summary
        Write-Warn 'Plan only - no artifact is produced, continuing.'
    }
    elseif ($AllowDirty) {
        Write-Warn $summary
        Write-Warn "-AllowDirty set: shipping the working tree even though release-metadata.json will report $localHead."
    }
    else {
        throw ("$summary`n`nRefusing to deploy: the web build compiles the working tree but stamps " +
            "commit $localHead, so uncommitted work would ship under a commit that does not " +
            "contain it. Commit your paths (git commit -m '...' -- <paths>) and re-run, or pass " +
            "-AllowDirty to override.")
    }
}

Write-Step "Checking web host $($config.ServerIp)..."
$null = Invoke-Remote 'echo ok'
Write-Info 'SSH connected'
Write-Host ''

$localNginxConfigHash = (Get-FileHash $localNginxConfigPath -Algorithm SHA256).Hash.ToLowerInvariant()
$remoteMetadata = Get-RemoteReleaseMetadata
$webDecision = Test-WebDeployRequired -LocalHead $localHead -LocalNginxConfigHash $localNginxConfigHash -RemoteMetadata $remoteMetadata

if ($PlanOnly) {
    Write-Step 'Web deploy plan'
    Write-Info "local_head=$localHead"
    Write-Info "local_pos_web_nginx_conf_sha256=$localNginxConfigHash"
    if ($remoteMetadata) {
        Write-Info "remote_web_commit=$($remoteMetadata.commit_sha)"
        Write-Info "remote_web_environment=$($remoteMetadata.environment)"
        Write-Info "remote_pos_web_nginx_conf_sha256=$($remoteMetadata.pos_web_nginx_conf_sha256)"
    }
    else {
        Write-Info 'remote_web_commit=unknown'
    }
    Write-Info "web_reason=$($webDecision.Reason)"
    Write-Output "WEB_DEPLOY_REQUIRED=$($webDecision.Required.ToString().ToLowerInvariant())"
    exit 0
}

if (-not $webDecision.Required) {
    Write-Info "Skipping web deploy: $($webDecision.Reason)"
    Write-Host ''
    exit 0
}

Write-Step 'Resolving Sentry release id...'
# Web builds shipped without SENTRY_RELEASE, so every web event landed in Sentry as
# the pubspec default "jarz_pos@1.0.0+1" — indistinguishable across builds and
# impossible to tie an error back to a commit. Reuse the same release_metadata tool
# the Android workflow uses so web and Android share one release scheme
# (e.g. staging-v1.0.0+327-c994c5f). build_release.bat forwards these as
# --dart-define when they are present in the environment.
Push-Location $repoRoot
try {
    $releaseMetaRaw = & dart run tool/release_metadata.dart --channel $Environment 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to resolve release metadata:`n$($releaseMetaRaw -join "`n")"
    }
}
finally {
    Pop-Location
}

$sentryRelease = ''
$sentryDist = ''
foreach ($line in $releaseMetaRaw) {
    if ("$line" -match '^RELEASE_ID=(.+)$') { $sentryRelease = $Matches[1].Trim() }
    elseif ("$line" -match '^BUILD_NUMBER=(.+)$') { $sentryDist = $Matches[1].Trim() }
}
if (-not $sentryRelease) {
    throw "Could not parse RELEASE_ID from release metadata output:`n$($releaseMetaRaw -join "`n")"
}

$env:SENTRY_RELEASE = $sentryRelease
$env:SENTRY_DIST = $sentryDist
Write-Info "sentry_release=$sentryRelease"
Write-Info "sentry_dist=$sentryDist"

Write-Step 'Building Flutter web release...'
$buildStdoutPath = [System.IO.Path]::GetTempFileName()
$buildStderrPath = [System.IO.Path]::GetTempFileName()
try {
    $buildCommand = """$repoRoot\scripts\build_release.bat"" $Environment web"
    if ($App -eq 'studio') {
        # The Studio app reads the POS env file and logs in against the Frappe site.
        $buildCommand = "flutter build web --release -t lib/main_studio.dart --base-href /studio/ --dart-define=ENV=$Environment --dart-define=SENTRY_ENVIRONMENT=$Environment --dart-define=SENTRY_RELEASE=$sentryRelease --dart-define=SENTRY_DIST=$sentryDist --dart-define-from-file=.env.$Environment"
    }
    $buildProcess = Start-Process -FilePath 'cmd.exe' `
        -ArgumentList '/c', $buildCommand `
        -WorkingDirectory $repoRoot `
        -NoNewWindow `
        -Wait `
        -PassThru `
        -RedirectStandardOutput $buildStdoutPath `
        -RedirectStandardError $buildStderrPath

    $buildOutput = @()
    if (Test-Path $buildStdoutPath) {
        $buildOutput += Get-Content -Path $buildStdoutPath
    }
    if (Test-Path $buildStderrPath) {
        $buildOutput += Get-Content -Path $buildStderrPath
    }

    if ($buildProcess.ExitCode -ne 0) {
        throw "Flutter web build failed ($($buildProcess.ExitCode))`n$($buildOutput -join "`n")"
    }

    if ($buildOutput) {
        $buildOutput | ForEach-Object { Write-Host $_ }
    }
}
finally {
    Remove-Item -Path $buildStdoutPath, $buildStderrPath -ErrorAction SilentlyContinue
}
Write-Host ''

$localMainPath = Join-Path $repoRoot 'build\web\main.dart.js'
if (-not (Test-Path $localMainPath)) {
    throw "Web build output not found at $localMainPath"
}

$localHash = (Get-FileHash $localMainPath -Algorithm SHA256).Hash.ToLowerInvariant()
$releaseMetadata = [ordered]@{
    commit_sha = $localHead
    environment = $Environment
    generated_at_utc = (Get-Date).ToUniversalTime().ToString('o')
    main_dart_js_sha256 = $localHash
    pos_web_nginx_conf_sha256 = $localNginxConfigHash
}
$localMetaPath = Join-Path $repoRoot 'build\web\release-metadata.json'
$releaseMetadata | ConvertTo-Json | Set-Content -Path $localMetaPath -Encoding UTF8

Write-Step 'Uploading web bundle to server...'
# Compute Linux parent path without PowerShell path manipulation (which converts / to \)
$remoteWebParentDir = $remoteWebDir.Substring(0, $remoteWebDir.TrimEnd('/').LastIndexOf('/' ))
$null = Invoke-Remote "rm -rf $remoteWebDir"
# scp -r of build\web into a path that no longer exists names the copy after that path:
# the POS build lands as pos-web/web, the Studio build as pos-web/studio-web.
$scpTarget = if ($App -eq 'studio') { $remoteWebDir } else { "$remoteWebParentDir/" }
& scp -o StrictHostKeyChecking=no -i $SshKeyPath -r "$repoRoot\build\web" "${sshTarget}:$scpTarget" 2>&1 | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) {
    throw 'Web bundle upload failed'
}
Write-Host ''

if ($App -eq 'pos') {
Write-Step 'Restoring the APK download bundle...'
# The web upload above wipes $remoteWebDir, so the internal APK download page is re-mirrored
# from its durable store (populated by scripts/publish_apk.ps1). Missing store is not an
# error: it just means no APK has been published to this server yet.
$restoreResult = Invoke-Remote "if [ -d $remoteDownloadStore ]; then mkdir -p $remoteServedDownloadDir && cp -a $remoteDownloadStore/. $remoteServedDownloadDir/ && echo restored; else echo absent; fi"
if ($restoreResult -eq 'restored') {
    Write-Info "APK download bundle restored to $remoteServedDownloadDir"
}
else {
    Write-Info 'No APK download store on this server yet; skipping'
}
Write-Host ''
}

Write-Step 'Uploading POS web server config...'
& scp -o StrictHostKeyChecking=no -i $SshKeyPath "$localNginxConfigPath" "${sshTarget}:$remoteNginxConfigPath" 2>&1 | ForEach-Object { Write-Host $_ }
if ($LASTEXITCODE -ne 0) {
    throw 'POS web server config upload failed'
}
Write-Host ''

if ($Environment -eq 'staging') {
    Write-Step 'Applying the tracked pos-web Dockerfile and compose file (staging)...'
    # The compose file is staged with LF endings whatever the checkout's autocrlf did.
    $composeTmp = [System.IO.Path]::GetTempFileName()
    try {
        $composeText = [System.IO.File]::ReadAllText($localComposePath) -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($composeTmp, $composeText, (New-Object System.Text.UTF8Encoding($false)))
        & scp -o StrictHostKeyChecking=no -i $SshKeyPath "$composeTmp" "${sshTarget}:$remoteComposePath" 2>&1 | ForEach-Object { Write-Host $_ }
        if ($LASTEXITCODE -ne 0) { throw 'pos-web compose upload failed' }
    }
    finally {
        Remove-Item -Path $composeTmp -ErrorAction SilentlyContinue
    }
    & scp -o StrictHostKeyChecking=no -i $SshKeyPath "$localDockerfilePath" "${sshTarget}:$remoteDockerfilePath" 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) { throw 'pos-web Dockerfile upload failed' }
    # The Dockerfile COPYs studio-web/, so the directory must exist even before a Studio deploy.
    $null = Invoke-Remote "mkdir -p $remoteStudioDir"
    Write-Host ''
}

Write-Step 'Rebuilding pos-web container...'
$null = Invoke-Remote "docker ps -aq --filter name=pos-web | xargs -r docker rm -f >/dev/null 2>&1 || true ; cd /home/ubuntu/pos-web && docker compose up -d --build --no-deps pos-web >/dev/null 2>&1 || docker-compose up -d --build --no-deps pos-web >/dev/null 2>&1"
Write-Info 'pos-web restarted'
Write-Host ''

Write-Step 'Verifying deployed web artifact...'
# Poll for the artifact, do not trust one read.
#
# The HTTP probe below already learned this lesson; the HASH read had not, and
# on 2026-08-26 it threw 'Could not read remote main.dart.js hash' on a
# production deploy that was entirely correct — the file appeared moments later
# and matched the local build byte for byte (7,233,494 bytes, same sha256).
# Between the scp and this read sit a `docker rm -f` and a `compose up --build`
# that recreate the container over the same directory, so a read landing in
# that gap sees nothing.
#
# The failure mode this prevents is worse than a slow deploy: a green deploy
# reported as a failure invites someone to "recover" a production POS that was
# never broken.
$remoteHash = $null
$hashDeadline = (Get-Date).AddSeconds(60)
do {
    $remoteHash = Get-RemoteMainHash
    if ($remoteHash) { break }
    Start-Sleep -Seconds 3
} while ((Get-Date) -lt $hashDeadline)

if (-not $remoteHash) {
    throw 'Could not read remote main.dart.js hash after web deploy (polled 60s)'
}
if ($remoteHash -ne $localHash) {
    throw "Remote web hash mismatch. local=$localHash remote=$remoteHash"
}
# The container was recreated seconds ago, so the first probe can land while
# nginx is still coming up and 404 on a deploy that is already correct — the
# byte-for-byte hash check above has passed by this point. That false failure
# has aborted a production deploy mid-chain, so poll instead of trusting one
# request. A genuinely broken deploy still fails, just 60s later.
$httpResponse = $null
$probeDeadline = (Get-Date).AddSeconds(60)
$probeError = $null
do {
    try {
        $httpResponse = Invoke-WebRequest -UseBasicParsing -Uri $config.PosUrl -TimeoutSec 30
    } catch {
        $probeError = $_
        if ((Get-Date) -lt $probeDeadline) {
            Write-Warn "POS web not answering yet; retrying..."
            Start-Sleep -Seconds 5
        }
    }
} while (-not $httpResponse -and (Get-Date) -lt $probeDeadline)

if (-not $httpResponse) {
    throw "POS web did not answer at $($config.PosUrl) within 60s after restart: $probeError"
}
Write-Info "Local main.dart.js hash: $localHash"
Write-Info "Remote main.dart.js hash: $remoteHash"
Write-Info "POS web HTTP status: $($httpResponse.StatusCode)"
Write-Host ''
