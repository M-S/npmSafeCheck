#!/bin/bash
# npm check if the packages installed or to be installed is safe or not
RED='\033[0;31m'
NC='\033[0m'
YLW='\033[1;33m'
GRN='\033[0;32m'
INSECURE_PACKAGES=$(jq -r '.[]' npmMalwareChecklist.json)
# INSECURE_PACKAGES=$(curl -s https://gist.githubusercontent.com/M-S/7cbfd290c446e228b0c0f1f301fe678b/raw/85a1a25aae2ce228eefd0b0fc85c62bc6b07a1a3/npmMalwareChecklist.json | jq -r '.[]')
FOUND_INSECURE_PACKAGES=0
PACKAGES_ALREADY_INSTALLED=$(npm ls --all)
for INSECURE_PKG in $(jq -r '.[]' npmMalwareChecklist.json); do
    if [ $(echo "$PACKAGES_ALREADY_INSTALLED" | grep "$INSECURE_PKG"  | wc -l) -gt 0 ]; then
    echo "${YLW}Warning: "$INSECURE_PKG" package found in the installed packages.${NC}"
    FOUND_INSECURE_PACKAGES=$((FOUND_INSECURE_PACKAGES + 1))
    fi
done 
  if [ $FOUND_INSECURE_PACKAGES -gt 0 ]; then
    echo "${RED}RED ALERT: INSECURE PACKAGES FOUND in the already installed packages.${YLW}"
    cat mitigationSteps.txt
    echo "${RED}RED ALERT: INSECURE PACKAGES FOUND in the already installed packages.Follow the above guidance${NC}"
    exit 1
  else
   echo "${GRN}No insecure packages found in the already installed packages.${NC}"
  fi
PACKAGES_TO_INSTALL=($(npm install --dry-run --silent --json | jq -r '.added[]? | select(.name) | .name'))
for PACKAGE in "${PACKAGES_TO_INSTALL[@]}"; do
  if echo "$INSECURE_PACKAGES" | grep -Fxq "$PACKAGE"; then
    echo -e "${YLW}Warning: Package $PACKAGE is listed as insecure.${NC}"
    FOUND_INSECURE_PACKAGES=$((FOUND_INSECURE_PACKAGES + 1))
  fi
done
if [ $FOUND_INSECURE_PACKAGES -gt 0 ]; then
  echo "${RED}Danger: Abort installation due to insecure package detection.${NC}"
  exit 1
else
echo "${GRN}All packages are safe.${NC}"
fi


