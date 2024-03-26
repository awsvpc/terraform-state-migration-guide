#!/usr/bin/env bash
set -euo pipefail

# Support aborting via SIGINT, without this bash will not exit the for loop until it's finished
trap 'exit 0' INT

# Usage example:
# bash migrate-state.sh '/home/myuser/terraform/destination-module' '/home/myuser/terraform/source-module' 'module.source' 'config/dev_backend.tfvars' 'config/dev_backend.tfvars'
# Arguments:
# $1 - destinationModuleDirectory: The directory in which the module resides where state should be moved to
# $2 - sourceModuleDirectory: The directory in which the module resides where state should be moved from
# $3 - destinationModuleSourceParentAddress: The resource address inside the destination module that is used as parent for all resources that are moved from the source module
# $4 (optional) - sourceModuleBackendConfig: The value that should be used for the "-backend-config" parameter when running  terraform init for the source module
# $5 (optional) - destinationModuleBackendConfig: The value that should be used for the "-backend-config" parameter when running  terraform init for the destination module
# Options:
# -dry-run
#   Show changes that will be made, does not actually change anything

function migrateState() {
  local destinationModuleDirectory="${1:?'The destinationModuleDirectory argument is missing'}"
  local sourceModuleDirectory="${2:?'The sourceModuleDirectory argument is missing'}"
  local destinationModuleSourceParentAddress="${3:?'The destinationModuleSourceParentAddress argument is missing'}"
  local sourceModuleBackendConfig="${4:-''}"
  local destinationModuleBackendConfig="${5:-''}"

  local isDryRun=0
  for arg in "${@}"
  do
    if [[ "${arg}" == '-dry-run' ]];
    then
      isDryRun=1
      break
    fi
  done

  local lightBlue='\e[38;5;26m'
  local colorEnd='\e[0m'

  local destinationModuleLocalStateFile="${destinationModuleDirectory}/destination-module.tfstate"

  cd "${destinationModuleDirectory}" || false

  local destinationTerraformInitArgs=''
  if [[ "${destinationModuleBackendConfig}" != '' ]];
  then
    destinationTerraformInitArgs="-backend-config=${destinationModuleBackendConfig}"
  fi
  terraform init "${destinationTerraformInitArgs}"

  terraform state pull > "${destinationModuleLocalStateFile}"
  cp "${destinationModuleLocalStateFile}" "${destinationModuleLocalStateFile}.bak"

  cd "${sourceModuleDirectory}" || false
  local sourceTerraformInitArgs=''
  if [[ "${sourceModuleBackendConfig}" != '' ]];
  then
    sourceTerraformInitArgs="-backend-config=${sourceModuleBackendConfig}"
  fi
  terraform init "${sourceTerraformInitArgs}"
  terraform state pull > "${sourceModuleDirectory}/source-module.tfstate.bak"

  for sourceResourceAddress in $(terraform state list)
  do
    local destinationResourceAddress="${destinationModuleSourceParentAddress}.${sourceResourceAddress}"
    printf "Moving ${lightBlue}%-100s${colorEnd} to ${lightBlue}%-120s${colorEnd}\n" "${sourceResourceAddress}" "${destinationResourceAddress}"

    if [[ ${isDryRun} == 1 ]];
    then
      terraform state mv -state-out="${destinationModuleLocalStateFile}" -dry-run "${sourceResourceAddress}" "${destinationResourceAddress}"
    else
      terraform state mv -state-out="${destinationModuleLocalStateFile}" "${sourceResourceAddress}" "${destinationResourceAddress}"
    fi

    printf '\n'
  done

  if [[ ${isDryRun} == 0 ]];
  then
    cd "${destinationModuleDirectory}" || false

    terraform init "${destinationTerraformInitArgs}"
    terraform state push "${destinationModuleLocalStateFile}"
  fi
}

migrateState "${@}"
