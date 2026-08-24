#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== [iLiving iOS Launch Script] ===${NC}"

# 1. Detect booted simulator ID or pick an available one
SIM_ID=$(xcrun simctl list devices | grep "(Booted)" | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' || true)

if [ -z "$SIM_ID" ]; then
  echo -e "${BLUE}[1/5] No booted simulator found. Detecting available iPhone...${NC}"
  SIM_ID=$(xcrun simctl list devices available | grep -E "iPhone" | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' || true)
  
  if [ -z "$SIM_ID" ]; then
    echo -e "${RED}[Error] No available iOS simulator found in Xcode.${NC}"
    exit 1
  fi

  echo -e "${BLUE}[1/5] Booting simulator ($SIM_ID)...${NC}"
  xcrun simctl boot "$SIM_ID" || true
  open -a Simulator
  xcrun simctl bootstatus "$SIM_ID" -b
else
  echo -e "${GREEN}[1/5] Using running simulator ($SIM_ID)...${NC}"
  open -a Simulator || true
fi

# 2. Build the app
echo -e "${GREEN}[2/5] Building app for simulator...${NC}"
flutter build ios --simulator --debug

# 3. Copy build to APFS storage (/tmp/Runner.app) to fix external USB drive permissions
echo -e "${GREEN}[3/5] Syncing build to APFS storage (/tmp/Runner.app)...${NC}"
rm -rf /tmp/Runner.app
cp -R build/ios/iphonesimulator/Runner.app /tmp/Runner.app

# 4. Install, Launch and Attach debugger directly with Flutter
echo -e "${GREEN}[4/4] Launching app on Simulator with Hot Reload...${NC}"
xcrun simctl terminate "$SIM_ID" com.hazemhany.iliving 2>/dev/null || true
flutter run --use-application-binary=/tmp/Runner.app -d "$SIM_ID"

