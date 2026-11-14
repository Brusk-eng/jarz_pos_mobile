#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

usage() {
  cat <<'EOF'
Usage: ./scripts/shorebird_android.sh <staging|production> <release|patch|doctor> [release-version]

Examples:
  ./scripts/shorebird_android.sh staging release
  ./scripts/shorebird_android.sh staging patch latest
  ./scripts/shorebird_android.sh production patch 1.0.0+195
EOF
}

if [ "$#" -lt 2 ]; then
  usage
  exit 1
fi

environment="$1"
action="$2"
release_version="${3:-${SHOREBIRD_PATCH_RELEASE_VERSION:-latest}}"

case "${environment,,}" in
  staging)
    env_define="staging"
    env_file=".env.staging"
    flavor="staging"
    sentry_environment="staging"
    built_apk="build/app/outputs/flutter-apk/app-staging-release.apk"
    named_apk="build/app/outputs/flutter-apk/jarz-pos-staging-release.apk"
    ;;
  production)
    env_define="prod"
    env_file=".env.prod"
    flavor="production"
    sentry_environment="production"
    built_apk="build/app/outputs/flutter-apk/app-production-release.apk"
    named_apk="build/app/outputs/flutter-apk/jarz-pos-production-release.apk"
    ;;
  *)
    echo "Unsupported environment: $environment" >&2
    usage
    exit 1
    ;;
esac

require_shorebird() {
  if ! command -v shorebird >/dev/null 2>&1; then
    echo "shorebird CLI is required. Install setup-shorebird in CI or install the CLI locally." >&2
    exit 1
  fi

  if [ ! -f shorebird.yaml ]; then
    echo "shorebird.yaml is missing. Run shorebird init and commit the generated flavor app IDs first." >&2
    exit 1
  fi
}

if [ "$action" = "doctor" ]; then
  require_shorebird
  shorebird doctor
  exit 0
fi

require_shorebird

build_args=(
  "--dart-define=ENV=$env_define"
  "--dart-define=SENTRY_ENVIRONMENT=$sentry_environment"
  "--dart-define-from-file=$env_file"
)

if [ -n "${SENTRY_RELEASE:-}" ]; then
  build_args+=("--dart-define=SENTRY_RELEASE=$SENTRY_RELEASE")
fi

if [ -n "${SENTRY_DIST:-}" ]; then
  build_args+=("--dart-define=SENTRY_DIST=$SENTRY_DIST")
fi

case "${action,,}" in
  release)
    if [ -n "${BUILD_NAME:-}" ]; then
      build_args+=("--build-name=$BUILD_NAME")
    fi
    if [ -n "${BUILD_NUMBER:-}" ]; then
      build_args+=("--build-number=$BUILD_NUMBER")
    fi

    echo "[shorebird_android] Creating $environment Shorebird Android release for flavor $flavor"
    shorebird release android --artifact apk --flavor "$flavor" -- "${build_args[@]}"
    if [ -f "$built_apk" ]; then
      cp "$built_apk" "$named_apk"
      echo "[shorebird_android] Named APK copied to $named_apk"
    fi
    ;;
  patch)
    if [ "$flavor" = "production" ] && { [ -z "$release_version" ] || [ "$release_version" = "latest" ]; }; then
      # A patch only reaches devices running the exact release version it targets. Patching
      # 'latest' silently misses every production device still on an older release, so require
      # an explicit version (the build production testers are running).
      echo "Production patches require an explicit release-version (e.g. 1.0.0+195). Refusing to patch 'latest' for production." >&2
      exit 1
    fi

    # --allow-build-flag-diffs: each build stamps its own SENTRY_RELEASE/SENTRY_DIST,
    # which a patch can never repeat; see shorebird_android.ps1.
    patch_args=(patch android --flavor "$flavor" --allow-build-flag-diffs)
    if [ -n "$release_version" ]; then
      patch_args+=(--release-version "$release_version")
    fi
    if [ -n "${SHOREBIRD_PATCH_TRACK:-}" ]; then
      patch_args+=(--track "$SHOREBIRD_PATCH_TRACK")
    fi

    echo "[shorebird_android] Creating $environment Shorebird Android patch for flavor $flavor, release $release_version"
    shorebird "${patch_args[@]}" -- "${build_args[@]}"
    ;;
  *)
    echo "Unsupported action: $action" >&2
    usage
    exit 1
    ;;
esac