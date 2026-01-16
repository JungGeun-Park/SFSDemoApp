#!/bin/sh

# === Color definitions for console output ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No color

CONFIG_FILE="sealing.config"

# === Global variables for path setting ===
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
basepath="${SCRIPT_DIR}/../.."

# === Logging helpers ===
success() { echo -e "${GREEN}✅ $1${NC}"; }
error()   { echo -e "${RED}❌ $1${NC}"; }
prompt()  { echo -e "${YELLOW}$1${NC}"; }

# === Spinner function for long tasks like archive/export ===
spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  local msg="$2"
  echo -n "$msg"
  while ps -p $pid > /dev/null 2>&1; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  echo "✅ Done"
}

# === Clear saved config if requested ===
if [ "$1" = "--clear" ]; then
  echo "🧹 Clearing saved configuration..."
  rm -f sealing.config
  echo "✅ Configuration cleared."
fi

# === Utility to prompt user for numbered list selection ===
prompt_choice() {
  local prompt_message="$1"
  local var_name="$2"
  local total="$3"
  local input=""
  while true; do
    prompt "$prompt_message ($total options)"
    read -p "🔎 Your choice: " input
    if [[ "$input" =~ ^[1-9][0-9]*$ ]] && [ "$input" -le "$total" ]; then
      eval "$var_name=$input"
      break
    else
      error "Invalid input. Please enter a number between 1 and $total."
    fi
  done
}

# === Load previous config if available ===
if [ -f "$CONFIG_FILE" ]; then
  echo "📦 Loading saved configuration from $CONFIG_FILE"
  . "$CONFIG_FILE"
fi

# === Setup logging and build folder ===
EXPORT_PATH="./Build"
LOG_FILE="$EXPORT_PATH/build.log"
mkdir -p "$EXPORT_PATH"
echo "📝 Saving detailed logs to: $LOG_FILE"

# === Detect Xcode project or workspace ===
echo "🔍 Scanning parent directory for .xcworkspace and .xcodeproj files..."
i=1
for f in $(find "$basepath" -maxdepth 1 \( -name "*.xcworkspace" -o -name "*.xcodeproj" \)); do
  printf "  📁  [%d] %s\n" "$i" "$f"
  eval "OPTION_$i=\"$f\""
  i=$((i + 1))
done

total=$((i - 1))
[ "$total" -eq 0 ] && error "No Xcode projects or workspaces found." && exit 1

# === Use cached project or prompt selection ===
if [ -n "$SELECTED_PROJECT" ]; then
  echo "📁 Using saved project: $SELECTED_PROJECT"
else
  prompt_choice "📁 Select a project or workspace" choice $total
  eval "SELECTED_PROJECT=\$OPTION_$choice"
  echo "SELECTED_PROJECT=\"$SELECTED_PROJECT\"" >> "$CONFIG_FILE"
fi

# === Determine whether it's a workspace or project ===
FILE_NAME=$(basename "$SELECTED_PROJECT")
EXT="${FILE_NAME##*.}"
if [ "$EXT" = "xcworkspace" ]; then
  FILE_FLAG="-workspace"
elif [ "$EXT" = "xcodeproj" ]; then
  FILE_FLAG="-project"
else
  error "Unknown file type." && exit 1
fi
success "Selected: $SELECTED_PROJECT"

# === List available build schemes from selected project ===
echo "🔍 Finding available schemes..."
SCHEME_LIST=$(xcodebuild -list $FILE_FLAG "$SELECTED_PROJECT" 2>>"$LOG_FILE" | awk '/Schemes:/,/^$/' | sed '1d;/^$/d')
i=1
echo "──────────────────────────────"
for scheme in $SCHEME_LIST; do
  printf "  🛠️  [%d] %s\n" "$i" "$scheme"
  eval "SCHEME_$i=\"$scheme\""
  i=$((i + 1))
done
echo "──────────────────────────────"

total_schemes=$((i - 1))
# === Use cached scheme or prompt ===
if [ -n "$SELECTED_SCHEME" ]; then
  echo "🛠️  Using saved scheme: $SELECTED_SCHEME"
else
  prompt_choice "🛠️ Select a build scheme" scheme_choice $total_schemes
  eval "SELECTED_SCHEME=\$SCHEME_$scheme_choice"
  echo "SELECTED_SCHEME=\"$SELECTED_SCHEME\"" >> "$CONFIG_FILE"
fi
success "Selected scheme: $SELECTED_SCHEME"

# === Set path to archive ===
ARCHIVE_PATH="$EXPORT_PATH/$(basename "$FILE_NAME" .$EXT).xcarchive"

# === Create export options file ===
cat > "$EXPORT_PATH/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store-connect</string>
  <key>uploadBitcode</key>
  <true/>
  <key>uploadSymbols</key>
  <true/>
</dict>
</plist>
EOF

# === Clean previous build artifacts ===
echo "🪚 Cleaning..."
xcodebuild clean $FILE_FLAG "$SELECTED_PROJECT" -scheme "$SELECTED_SCHEME" >> "$LOG_FILE" 2>&1

# === Archive build ===
echo "\n📆 Archiving..."
xcodebuild archive \
  $FILE_FLAG "$SELECTED_PROJECT" \
  -scheme "$SELECTED_SCHEME" \
  -archivePath "$ARCHIVE_PATH" \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  >> "$LOG_FILE" 2>&1 &
ARCHIVE_PID=$!
spinner $ARCHIVE_PID "⌛ Archiving in progress..."
[ ! -d "$ARCHIVE_PATH" ] && error "Archive failed." && exit 1

# === Export IPA from archive ===
echo "\n📲 Exporting IPA..."
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_PATH/ExportOptions.plist" \
  -allowProvisioningUpdates \
  >> "$LOG_FILE" 2>&1 &
EXPORT_PID=$!
spinner $EXPORT_PID "⌛ Exporting IPA..."
rm "$EXPORT_PATH/ExportOptions.plist" 2>/dev/null
success "IPA exported to: $EXPORT_PATH"

# === Scan for generated IPA files ===
IPA_LIST=$(find "$EXPORT_PATH" -name "*.ipa")
[ -z "$IPA_LIST" ] && error "No IPA files found in $EXPORT_PATH" && exit 1
i=1
echo "──────────────────────────────"
for ipa in $IPA_LIST; do
  printf "  📲  [%d] %s\n" "$i" "$ipa"
  eval "IPA_$i=\"$ipa\""
  i=$((i + 1))
done
echo "──────────────────────────────"

total_ipas=$((i - 1))
# === Use cached or prompt for IPA ===
if [ -n "$SELECTED_IPA" ]; then
  echo "📲 Using saved IPA: $SELECTED_IPA"
else
  prompt_choice "📦 Select an IPA to apply AppSealing" ipa_choice $total_ipas
  eval "SELECTED_IPA=\$IPA_$ipa_choice"
  echo "SELECTED_IPA=\"$SELECTED_IPA\"" >> "$CONFIG_FILE"
fi
success "Selected IPA: $SELECTED_IPA"

# === Prompt for Anti-Swizzling setting ===
if [ -n "$ENABLE_SWIZZLING" ]; then
  echo "🧪 Using saved Anti-Swizzle option: $ENABLE_SWIZZLING"
else
  prompt "🧪 Enable Anti-Swizzle? (Y/N):"
  read -p "🔎 Your choice: " ENABLE_SWIZZLING
  echo "ENABLE_SWIZZLING=$ENABLE_SWIZZLING" >> "$CONFIG_FILE"
fi
case "$ENABLE_SWIZZLING" in
  n|N|no|No) ANTISWIZZLE_FLAG="-antiswizzle=disable" ;;
  *)         ANTISWIZZLE_FLAG="-antiswizzle=enable" ;;
esac

# === Prompt for Anti-Hook setting ===
if [ -n "$DISABLE_HOOK" ]; then
  echo "🛡️  Using saved Anti-Hook option: $DISABLE_HOOK"
else
  prompt "🛡️ Disable Anti-Hook? (Y/N):"
  read -p "🔎 Your choice: " DISABLE_HOOK
  echo "DISABLE_HOOK=$DISABLE_HOOK" >> "$CONFIG_FILE"
fi
case "$DISABLE_HOOK" in
  y|Y|yes|Yes) ANTIHOOK_FLAG="-antihook=disable" ;;
  *)           ANTIHOOK_FLAG="-antihook=enable" ;;
esac

# === Run sealing tool with selected options ===
HASH_SCRIPT="$SCRIPT_DIR/generate_hash"
[ ! -x "$HASH_SCRIPT" ] && error "$HASH_SCRIPT not found or not executable" && exit 1
SELECTED_IPA_ABS=$(cd "$(dirname "$SELECTED_IPA")" && pwd)/$(basename "$SELECTED_IPA")
[ ! -f "$SELECTED_IPA_ABS" ] && error "IPA not found at: $SELECTED_IPA_ABS" && exit 1

echo "🔐 Running sealing tool..."
"$HASH_SCRIPT" "$SELECTED_IPA_ABS" "$ANTISWIZZLE_FLAG" "$ANTIHOO_K_FLAG" >> "$LOG_FILE" 2>&1

# === Done ===
success "All steps completed."
echo "📜 Full logs: $LOG_FILE"
open "$EXPORT_PATH"
