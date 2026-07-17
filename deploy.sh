#!/bin/bash
set -e

# ============================================================
# deploy.sh — Automate Flutter APK release & publish
#
# Usage:
#   ./deploy.sh "<changelog>" [options]
#
# Options:
#   --dev        Build + publish ke backend lokal (test dulu)
#   --force      Paksa semua user update (forceUpdate: true)
#   --min <ver>  Set minVersion (default: versi sebelumnya)
#
# Alur yang disarankan:
#   1. ./deploy.sh "Fix Bug" --dev    ← test di lokal dulu
#   2. ./deploy.sh "Fix Bug"          ← production jika oke
# ============================================================

CHANGELOG=$1

# --- Parse flags ---
MODE="production"
FORCE_UPDATE="false"
MIN_VERSION_OVERRIDE=""

shift 1 2>/dev/null || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dev)   MODE="dev" ;;
    --force) FORCE_UPDATE="true" ;;
    --min)   MIN_VERSION_OVERRIDE="$2"; shift ;;
    *)       echo "Unknown flag: $1"; exit 1 ;;
  esac
  shift
done

# --- Config ---
FILE_NAME="app-release.apk"
APK_OUTPUT="build/app/outputs/flutter-apk/app-release.apk"
UPDATE_TOKEN="${UPDATE_TOKEN:-"UTAMA-UPDATE-SECRET-123"}"
APP_ID="mobile"

DEV_IP="192.168.11.153"
PROD_IP="192.168.11.79"
PORT="7500"

DEV_SERVER="http://$DEV_IP:$PORT"
PROD_SERVER="http://$PROD_IP:$PORT"

if [ "$MODE" == "dev" ]; then
  APP_ENV="development"
  ENV_FILE=".env.development"
  PUBLISH_SERVER="$DEV_SERVER"
else
  APP_ENV="production"
  ENV_FILE=".env.production"
  PUBLISH_SERVER="$PROD_SERVER"
fi

PUBLISH_URL="$PUBLISH_SERVER/api/update/$APP_ID/publish"

# --- Validation ---
if [ -z "$CHANGELOG" ]; then
  echo ""
  echo "Usage: ./deploy.sh \"<changelog>\" [--dev] [--force] [--min <ver>]"
  echo ""
  echo "Examples:"
  echo "  ./deploy.sh \"Fix Bug\"              # production"
  echo "  ./deploy.sh \"Fix Bug\" --dev         # test lokal dulu"
  echo "  ./deploy.sh \"Fix Bug\" --force       # production force update"
  echo "  ./deploy.sh \"Fix Bug\" --min 1.0.25  # set min version"
  echo ""
  exit 1
fi

# --- Auto increment version dari pubspec.yaml ---
CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
CURRENT_BUILD=$(grep '^version:' pubspec.yaml | sed 's/.*+//')

MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)

NEXT_PATCH=$((PATCH + 1))
NEXT_VERSION="$MAJOR.$MINOR.$NEXT_PATCH"
NEXT_BUILD=$((CURRENT_BUILD + 1))

MIN_VERSION="${MIN_VERSION_OVERRIDE:-$CURRENT_VERSION}"

echo ""
echo "=================================================="
echo " PPS Mobile — Deploy Script"
echo "=================================================="
echo " Mode        : $MODE"
echo " App Env     : $APP_ENV ($ENV_FILE)"
echo " Server      : $PUBLISH_SERVER"
echo " Version     : $CURRENT_VERSION+$CURRENT_BUILD → $NEXT_VERSION+$NEXT_BUILD"
echo " Min Version : $MIN_VERSION"
echo " Force Update: $FORCE_UPDATE"
echo " Changelog   : $CHANGELOG"
echo "=================================================="
echo ""

if [ "$MODE" == "production" ]; then
  echo "  WARNING: PRODUCTION — update akan diterima semua user!"
  echo ""
fi

read -p "Lanjutkan deploy? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Deploy dibatalkan."
  exit 0
fi

# --- Step 1: Update pubspec.yaml version ---
echo ""
echo "[1/5] Updating version in pubspec.yaml..."
sed -i "s/^version: .*/version: $NEXT_VERSION+$NEXT_BUILD/" pubspec.yaml
echo "      Done: $CURRENT_VERSION+$CURRENT_BUILD → $NEXT_VERSION+$NEXT_BUILD"

# --- Step 2: Validate env file ---
echo ""
echo "[2/5] Validating environment ($APP_ENV)..."
if [ ! -f "$ENV_FILE" ]; then
  echo "      ERROR: $ENV_FILE tidak ditemukan"
  exit 1
fi

echo "      Done: using $ENV_FILE"

# --- Step 3: Build APK release ---
echo ""
echo "[3/5] Building APK release (this may take a few minutes)..."
flutter build apk --release --dart-define=APP_ENV="$APP_ENV"
echo "      Done: APK built"

# --- Step 4: Show APK info ---
echo ""
echo "[4/5] APK ready..."
APK_SIZE=$(du -sh "$APK_OUTPUT" | cut -f1)
echo "      $APK_OUTPUT ($APK_SIZE)"

# --- Step 5: Upload APK + metadata to server ---
echo ""
echo "[5/5] Uploading APK and publishing update ($MODE)..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$PUBLISH_URL" \
  -H "x-update-token: $UPDATE_TOKEN" \
  -F "apk=@$APK_OUTPUT;filename=$FILE_NAME" \
  -F "latestVersion=$NEXT_VERSION" \
  -F "minVersion=$MIN_VERSION" \
  -F "forceUpdate=$FORCE_UPDATE" \
  -F "changelog=$CHANGELOG")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "201" ]; then
  echo "      Done: Server responded $HTTP_CODE"
  echo "      Response: $BODY"
else
  echo "      ERROR: Server responded $HTTP_CODE"
  echo "      Response: $BODY"
  exit 1
fi

echo ""
echo "=================================================="
if [ "$MODE" == "dev" ]; then
  echo " Dev deploy selesai! Versi $NEXT_VERSION tersedia di lokal."
  echo " Test di device, lalu jalankan:"
  echo "   ./deploy.sh \"$CHANGELOG\" untuk production"
else
  echo " Deploy selesai! Version $NEXT_VERSION berhasil publish ke production."
fi
echo "=================================================="
echo ""
