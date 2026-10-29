#!/bin/bash
#
# strip_unused_localizations.sh
#
# Removes Stripe SDK localizations that your app doesn't support, reducing the
# size of your app. The Stripe SDK ships translations for 40+ locales, but iOS
# only ever displays Stripe UI in a language that the Stripe bundle supports,
# so any locale your app itself isn't localized into is usually dead weight.
#
# The script only touches Stripe resource bundles and frameworks (bundles or
# frameworks named `Stripe*` or `*_Stripe*`). It never modifies your app's own
# resources or other third-party SDKs.
#
# USAGE (Xcode build phase, recommended):
#   1. In your app target's Build Phases, add a "New Run Script Phase" and move
#      it to the very end, after "Embed Frameworks" and any CocoaPods phases.
#   2. Set the script to one of the following:
#        Swift Package Manager:
#          "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/stripe-ios-spm/StripeCore/Scripts/strip_unused_localizations.sh"
#        CocoaPods:
#          "${PODS_ROOT}/StripeCore/StripeCore/Scripts/strip_unused_localizations.sh"
#      Or paste the contents of this file directly into the build phase.
#   3. Uncheck "Based on dependency analysis" so the phase runs on every build.
#   4. If your target sets ENABLE_USER_SCRIPT_SANDBOXING = YES (the default for
#      projects created in Xcode 15 or later), set it to NO for that target.
#      The script needs to modify the built app bundle.
#
# USAGE (command line, e.g. on an unsigned .xcarchive):
#   strip_unused_localizations.sh path/to/MyApp.app
#   When run outside of Xcode, modified frameworks are not re-signed. Re-sign
#   the app (e.g. by exporting the archive) before distributing it.
#
# WHICH LOCALIZATIONS ARE KEPT:
#   - Every locale your app is localized into (the .lproj directories in your
#     app bundle and CFBundleLocalizations in your Info.plist).
#   - Regional variants of those languages. For example, if your app supports
#     "es", Stripe's "es" and "es-419" are both kept.
#   - "Base", English (the Stripe SDK's development language), and your app's
#     development language.
#
# CONFIGURATION (set as environment variables or build settings):
#   STRIPE_KEEP_LOCALIZATIONS   Space- or comma-separated list of locales to
#                               keep instead of detecting them from your app,
#                               e.g. "en fr de". Base and English are always kept.
#   STRIPE_STRIP_LOCALIZATIONS_DRY_RUN
#                               Set to YES to log what would be removed without
#                               removing anything.

set -euo pipefail

log() { echo "[strip_unused_localizations] $*"; }
warn() { echo "warning: [strip_unused_localizations] $*"; }
fail() {
  echo "error: [strip_unused_localizations] $*" >&2
  exit 1
}

# Lowercases a locale and normalizes `_` to `-`, so `zh_HK` matches `zh-HK`.
normalize_locale() {
  echo "$1" | tr '[:upper:]_' '[:lower:]-'
}

# Sets LANGUAGE to the language portion of the normalized locale $1 (e.g. `pt`
# for `pt-br`), mapping legacy and alternative language codes to the ones the
# Stripe SDK uses. Sets a variable instead of printing to avoid a subshell per call.
language_of() {
  LANGUAGE="${1%%-*}"
  case "$LANGUAGE" in
    english) LANGUAGE="en" ;;
    french) LANGUAGE="fr" ;;
    german) LANGUAGE="de" ;;
    spanish) LANGUAGE="es" ;;
    italian) LANGUAGE="it" ;;
    japanese) LANGUAGE="ja" ;;
    dutch) LANGUAGE="nl" ;;
    no | nn) LANGUAGE="nb" ;;
    tl) LANGUAGE="fil" ;;
    in) LANGUAGE="id" ;;
  esac
}

# Prints the CFBundleDevelopmentRegion of the bundle or framework at $1, if any.
development_region_of() {
  local plist
  for plist in "$1/Info.plist" "$1/Contents/Info.plist" "$1/Resources/Info.plist"; do
    if [ -f "$plist" ]; then
      /usr/libexec/PlistBuddy -c "Print :CFBundleDevelopmentRegion" "$plist" 2>/dev/null || true
      return
    fi
  done
}

# MARK: - Locate the app bundle

DRY_RUN="${STRIPE_STRIP_LOCALIZATIONS_DRY_RUN:-NO}"
CAN_RESIGN=NO

if [ $# -gt 0 ]; then
  # Command-line mode.
  APP_BUNDLE="${1%/}"
  [ -d "$APP_BUNDLE" ] || fail "App bundle not found: $APP_BUNDLE"
  if [ -d "$APP_BUNDLE/Contents" ]; then
    # macOS / Mac Catalyst layout
    RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"
    FRAMEWORKS_DIR="$APP_BUNDLE/Contents/Frameworks"
    INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"
  else
    RESOURCES_DIR="$APP_BUNDLE"
    FRAMEWORKS_DIR="$APP_BUNDLE/Frameworks"
    INFO_PLIST="$APP_BUNDLE/Info.plist"
  fi
  APP_DEVELOPMENT_LANGUAGE=""
else
  # Xcode build phase mode.
  if [ -z "${TARGET_BUILD_DIR:-}" ] || [ -z "${WRAPPER_NAME:-}" ]; then
    fail "Run this script from an Xcode Run Script build phase, or pass the path to a .app bundle."
  fi
  if [ "${ENABLE_USER_SCRIPT_SANDBOXING:-NO}" = "YES" ]; then
    fail "This script needs to modify the built app, which the Xcode script sandbox prevents. Set ENABLE_USER_SCRIPT_SANDBOXING to NO for target '${TARGET_NAME:-unknown}'."
  fi
  APP_BUNDLE="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
  RESOURCES_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH:-$WRAPPER_NAME}"
  FRAMEWORKS_DIR="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH:-$WRAPPER_NAME/Frameworks}"
  INFO_PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH:-$WRAPPER_NAME/Info.plist}"
  APP_DEVELOPMENT_LANGUAGE="${DEVELOPMENT_LANGUAGE:-}"
  if [ "${CODE_SIGNING_ALLOWED:-NO}" = "YES" ] && [ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ]; then
    CAN_RESIGN=YES
  fi
  if [ ! -d "$APP_BUNDLE" ]; then
    log "App bundle not found at $APP_BUNDLE, skipping."
    exit 0
  fi
fi

# MARK: - Build the list of locales to keep

APP_LOCALES=""
add_app_locale() {
  [ -n "$1" ] && APP_LOCALES="$APP_LOCALES $1"
  return 0
}

if [ -n "${STRIPE_KEEP_LOCALIZATIONS:-}" ]; then
  for locale in ${STRIPE_KEEP_LOCALIZATIONS//,/ }; do
    add_app_locale "$locale"
  done
  log "Using STRIPE_KEEP_LOCALIZATIONS:${APP_LOCALES}"
else
  # 1. The app's own .lproj directories.
  for lproj in "$RESOURCES_DIR"/*.lproj; do
    [ -d "$lproj" ] || continue
    add_app_locale "$(basename "$lproj" .lproj)"
  done

  # 2. CFBundleLocalizations and CFBundleDevelopmentRegion from the app's Info.plist.
  if [ -f "$INFO_PLIST" ]; then
    index=0
    while locale="$(/usr/libexec/PlistBuddy -c "Print :CFBundleLocalizations:$index" "$INFO_PLIST" 2>/dev/null)"; do
      add_app_locale "$locale"
      index=$((index + 1))
    done
    if [ -z "$APP_DEVELOPMENT_LANGUAGE" ]; then
      APP_DEVELOPMENT_LANGUAGE="$(/usr/libexec/PlistBuddy -c "Print :CFBundleDevelopmentRegion" "$INFO_PLIST" 2>/dev/null || true)"
    fi
  fi
fi

# 3. The app's development language. This is what iOS displays when the user
#    prefers a language the app doesn't support.
add_app_locale "$APP_DEVELOPMENT_LANGUAGE"

# Precompute the normalized locales and languages to keep. Base and English
# (the Stripe SDK's development language) are the fallbacks iOS uses when no
# other localization matches, so they're always kept.
KEEP_LOCALES=" base "
KEEP_LANGUAGES=" en "
for app_locale in $(normalize_locale "$APP_LOCALES"); do
  KEEP_LOCALES="$KEEP_LOCALES$app_locale "
  language_of "$app_locale"
  KEEP_LANGUAGES="$KEEP_LANGUAGES$LANGUAGE "
done

# Returns success if the normalized Stripe locale $1 should be kept in a bundle
# whose development language is $2.
should_keep() {
  case "$KEEP_LOCALES" in *" $1 "*) return 0 ;; esac
  language_of "$1"
  case "$KEEP_LANGUAGES" in *" $LANGUAGE "*) return 0 ;; esac
  [ -n "$2" ] && [ "$LANGUAGE" = "$2" ]
}

# MARK: - Find Stripe bundles and frameworks

STRIPE_CONTAINERS=()
shopt -s nullglob
for bundle in "$RESOURCES_DIR"/*.bundle; do
  # Swift Package Manager (`Stripe_StripeCore.bundle`) and static CocoaPods
  # (`StripeCoreBundle.bundle`) resource bundles.
  case "$(basename "$bundle")" in
    Stripe* | *_Stripe*) STRIPE_CONTAINERS+=("$bundle") ;;
  esac
done
for framework in "$FRAMEWORKS_DIR"/Stripe*.framework; do
  # XCFrameworks, Carthage, and CocoaPods with `use_frameworks!`.
  # CocoaPods resource bundles live inside the framework.
  STRIPE_CONTAINERS+=("$framework")
done
shopt -u nullglob

if [ ${#STRIPE_CONTAINERS[@]} -eq 0 ]; then
  warn "No Stripe resource bundles or frameworks found in $APP_BUNDLE. Make sure this build phase runs after Stripe's resources are copied."
  exit 0
fi

log "Keeping localizations matching:${APP_LOCALES:- (none detected)} (Base and English are always kept)"
[ "$DRY_RUN" = "YES" ] && log "Dry run: nothing will be removed."

# MARK: - Strip localizations

removed_count=0
removed_kb=0
for container in "${STRIPE_CONTAINERS[@]}"; do
  development_language=""
  development_region="$(development_region_of "$container")"
  if [ -n "$development_region" ]; then
    language_of "$(normalize_locale "$development_region")"
    development_language="$LANGUAGE"
  fi

  unused_lprojs=()
  while IFS= read -r -d '' lproj; do
    locale="${lproj##*/}"
    locale="${locale%.lproj}"
    should_keep "$(normalize_locale "$locale")" "$development_language" && continue
    unused_lprojs+=("$lproj")
    [ "$DRY_RUN" = "YES" ] && log "Would remove ${lproj#"$APP_BUNDLE"/}"
  done < <(find "$container" -type d -name '*.lproj' -prune -print0)

  [ ${#unused_lprojs[@]} -eq 0 ] && continue
  removed_count=$((removed_count + ${#unused_lprojs[@]}))
  removed_kb=$((removed_kb + $(du -skc "${unused_lprojs[@]}" | tail -n 1 | cut -f1)))
  [ "$DRY_RUN" = "YES" ] && continue
  rm -rf "${unused_lprojs[@]}"

  # Frameworks are signed when they're embedded, so modifying them invalidates
  # their signature. Resource bundles at the top level of the app are covered
  # by the app's signature, which Xcode applies after all build phases run.
  if [[ "$container" == *.framework ]]; then
    if [ "$CAN_RESIGN" = "YES" ]; then
      log "Re-signing ${container##*/}"
      # OTHER_CODE_SIGN_FLAGS is intentionally unquoted so it splits into separate flags.
      # shellcheck disable=SC2086
      /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" ${OTHER_CODE_SIGN_FLAGS:-} \
        --preserve-metadata=identifier,entitlements,flags --timestamp=none "$container"
    elif /usr/bin/codesign --display "$container" >/dev/null 2>&1; then
      warn "Modified signed framework ${container##*/}. Re-sign the app before distributing it."
    fi
  fi
done

if [ "$DRY_RUN" = "YES" ]; then
  log "Would remove $removed_count localization directories (${removed_kb} KB) from ${#STRIPE_CONTAINERS[@]} Stripe bundles and frameworks."
else
  log "Removed $removed_count localization directories (${removed_kb} KB) from ${#STRIPE_CONTAINERS[@]} Stripe bundles and frameworks."
fi
