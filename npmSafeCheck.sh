#!/bin/bash
# Script to check if installed or to-be-installed npm packages are listed as insecure

# Color codes for output formatting
RED='\033[0;31m'
NC='\033[0m'
YLW='\033[1;33m'
GRN='\033[0;32m'

# Load insecure package names from JSON file
INSECURE_PACKAGES=$(jq -r '.[]' npmMalwareChecklist.json)
# Alternative: Fetch insecure package list from remote source
# INSECURE_PACKAGES=$(curl -s https://gist.githubusercontent.com/M-S/7cbfd290c446e228b0c0f1f301fe678b/raw/85a1a25aae2ce228eefd0b0fc85c62bc6b07a1a3/npmMalwareChecklist.json | jq -r '.[]')

FOUND_INSECURE_PACKAGES=0

# Get list of already installed npm packages
PACKAGES_ALREADY_INSTALLED=$(npm ls --all 2> /dev/null)

if [ $? -eq 0 ]; then
  echo "${GRN}Checking already installed npm packages...${NC}"
  # Check if any installed package matches the insecure list
  for INSECURE_PKG in $(jq -r '.[]' npmMalwareChecklist.json); do
    if [ "$(echo "$PACKAGES_ALREADY_INSTALLED" | grep -c "$INSECURE_PKG")" -gt 0 ]; then
      echo "${YLW}Warning: $INSECURE_PKG package found in the installed packages.${NC}"
      FOUND_INSECURE_PACKAGES=$((FOUND_INSECURE_PACKAGES + 1))
    fi
  done 

  # If insecure packages are found among installed packages, show alert and mitigation steps
  if [ $FOUND_INSECURE_PACKAGES -gt 0 ]; then
    echo "${RED}RED ALERT: INSECURE PACKAGES FOUND in the already installed packages.${YLW}"
    cat mitigationSteps.txt
    echo "${RED}RED ALERT: INSECURE PACKAGES FOUND in the already installed packages.Follow the above guidance${NC}"
    #exit 1
  else
    echo "${GRN}No insecure packages found in the already installed packages.${NC}"
  fi
else
  echo "${RED}Error: Failed to retrieve pre installed npm packages. Ensure you are in a valid npm project directory.${NC}"
fi


echo "${GRN}Checking to-be-installed npm packages...${NC}"
# Simulate npm install to get list of packages that would be installed
PACKAGES_TO_INSTALL=$(npm install --dry-run --silent --json | jq -r '.added[]? | select(.name) | .name' 2> /dev/null)

if [ $? -ne 0 ]; then
  echo "${RED}Error: Failed to simulate npm install. Ensure you are in a valid npm project directory.${NC}"
  exit 1
fi
if [ ! ${PACKAGES_TO_INSTALL} ]; then
  echo "${GRN}No new packages to install.${NC}"
  exit 0
fi
# Check if any to-be-installed package matches the insecure list
for PACKAGE in "${PACKAGES_TO_INSTALL[@]}"; do
  if echo "$INSECURE_PACKAGES" | grep -Fxq "$PACKAGE"; then
    echo -e "${YLW}Warning: Package $PACKAGE is listed as insecure.${NC}"
    FOUND_INSECURE_PACKAGES=$((FOUND_INSECURE_PACKAGES + 1))
  fi
done

# If insecure packages are found among to-be-installed packages, abort installation
if [ $FOUND_INSECURE_PACKAGES -gt 0 ]; then
  echo "${RED}Danger: DO NOT INSTALL or UPGRADE packages due to potential insecure package detection in future install.${NC}"
  exit 1
else
  echo "${GRN}All packages are safe.${NC}"
fi
