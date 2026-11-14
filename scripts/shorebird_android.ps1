param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('staging', 'production')]
    [string]$Environment,

    [Parameter(Mandatory = $true)]
    [ValidateSet('release', 'patch', 'doctor')]
    [string]$Action,

    [string]$ReleaseVersion = 'latest',
    [string]$Track,
    [string]$BuildName,
    [string]$BuildNumber,

    # Flutter version to build the release with. Defaults to the FLUTTER_VERSION
    # the workflow already pins for every other build step.
    [string]$FlutterVersion = $env:FLUTTER_VERSION
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Resolve-AndroidConfig([string]$TargetEnvironment) {
    switch ($TargetEnvironment) {
        'staging' {
            return @{
                EnvDefine = 'staging'
                EnvFile = '.env.staging'
                Flavor = 'staging'
                SentryEnvironment = 'staging'
                NamedApk = 'build\app\outputs\flutter-apk\jarz-pos-staging-release.apk'
                BuiltApk = 'build\app\outputs\flutter-apk\app-staging-release.apk'
            }
        }
        'production' {
            return @{
                EnvDefine = 'prod'
                EnvFile = '.env.prod'
                Flavor = 'production'
                SentryEnvironment = 'production'
                NamedApk = 'build\app\outputs\flutter-apk\jarz-pos-production-release.apk'
                BuiltApk = 'build\app\outputs\flutter-apk\app-production-release.apk'
            }
        }
    }
}

function Assert-ShorebirdReady {
    if (-not (Get-Command shorebird -ErrorAction SilentlyContinue)) {
        throw 'shorebird CLI is required. Install it, run shorebird doctor, and authenticate before publishing Android releases or patches.'
    }

    if (-not (Test-Path 'shorebird.yaml')) {
        throw 'shorebird.yaml is missing. Run shorebird init from the Flutter app root and commit the generated flavor app IDs before using this script.'
    }
}

$config = Resolve-AndroidConfig $Environment

if ($Action -eq 'doctor') {
    Assert-ShorebirdReady
    & shorebird doctor
    exit $LASTEXITCODE
}

Assert-ShorebirdReady

$buildArgs = @(
    "--dart-define=ENV=$($config.EnvDefine)",
    "--dart-define=SENTRY_ENVIRONMENT=$($config.SentryEnvironment)",
    "--dart-define-from-file=$($config.EnvFile)"
)

if ($env:SENTRY_RELEASE) {
    $buildArgs += "--dart-define=SENTRY_RELEASE=$($env:SENTRY_RELEASE)"
}
if ($env:SENTRY_DIST) {
    $buildArgs += "--dart-define=SENTRY_DIST=$($env:SENTRY_DIST)"
}

if ($Action -eq 'release') {
    if ($BuildName) {
        $buildArgs += "--build-name=$BuildName"
    }
    elseif ($env:BUILD_NAME) {
        $buildArgs += "--build-name=$($env:BUILD_NAME)"
    }

    if ($BuildNumber) {
        $buildArgs += "--build-number=$BuildNumber"
    }
    elseif ($env:BUILD_NUMBER) {
        $buildArgs += "--build-number=$($env:BUILD_NUMBER)"
    }

    # Pin the Flutter version. Left unset, `shorebird release` ignores the Flutter
    # the workflow set up and pulls the LATEST stable instead, which is how a
    # production release build died on "your project's Gradle version (8.12.0) is
    # lower than Flutter's minimum supported version of 8.14.0" while every patch
    # kept building - a patch inherits the Flutter of the release it targets, so
    # only the release path ever saw the newer toolchain.
    $releaseArgs = @('release', 'android', '--artifact', 'apk', '--flavor', $config.Flavor)
    if ($FlutterVersion) {
        $releaseArgs += @('--flutter-version', $FlutterVersion)
        Write-Host "[shorebird_android] Pinning release to Flutter $FlutterVersion"
    }
    else {
        Write-Warning "[shorebird_android] No FlutterVersion/FLUTTER_VERSION set; Shorebird will use the latest stable Flutter, which may not match this project's Gradle version."
    }

    Write-Host "[shorebird_android] Creating $Environment Shorebird Android release for flavor $($config.Flavor)"
    & shorebird @releaseArgs '--' @buildArgs
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    if (Test-Path $config.BuiltApk) {
        Copy-Item -Force $config.BuiltApk $config.NamedApk
        Write-Host "[shorebird_android] Named APK copied to $($config.NamedApk)"
    }
    exit 0
}

if ($Environment -eq 'production' -and ([string]::IsNullOrWhiteSpace($ReleaseVersion) -or $ReleaseVersion -eq 'latest')) {
    # A patch only reaches devices running the exact release version it targets. Patching
    # 'latest' silently misses every production device still on an older release, so require
    # an explicit version (the build production testers are running).
    throw "Production patches require an explicit -ReleaseVersion (e.g. 1.4.0+182). Refusing to patch 'latest' for production."
}

# --allow-build-flag-diffs: every build stamps its own SENTRY_RELEASE / SENTRY_DIST
# (build number + commit), so a patch can never repeat its release's values, and
# Shorebird now refuses the mismatch (staging run 43603586129, 2026-11-14). Those
# two only label Sentry events; ENV, SENTRY_ENVIRONMENT and the env file still
# come from the same config as the release.
$patchArgs = @('patch', 'android', '--flavor', $config.Flavor, '--allow-build-flag-diffs')
if ($ReleaseVersion) {
    $patchArgs += @('--release-version', $ReleaseVersion)
}
if ($Track) {
    $patchArgs += @('--track', $Track)
}

Write-Host "[shorebird_android] Creating $Environment Shorebird Android patch for flavor $($config.Flavor), release $ReleaseVersion"
& shorebird @patchArgs '--' @buildArgs
exit $LASTEXITCODE