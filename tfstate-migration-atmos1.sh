#!/usr/bin/env bash
###
### This is intended to be copied and stored alongside your Terraform code. This keeps a historical record of your various migrations.
### It requires editing for each migration that you want to do according to the source + destination root modules and the resources you intend to move. 
###
### This is dependent on the $ATMOS_STACK environment variable (available when using Atmos / Spacelift automated via https://github.com/cloudposse/terraform-spacelift-cloud-infrastructure-automation) 
### for the WORKSPACE that you're moving from, but you can obviously update that if you're not working in that environment.

set -eu -o pipefail

SRC_COMPONENT="<SRC ROOT MODULE NAME>"
DESTINATION_COMPONENT="<DESTINATION ROOT MODULE NAME>"
WORKSPACE=$ATMOS_STACK
DATE=$(date +"%Y-%m-%d")
STATE_FILE=migration-$DATE.tfstate

function mv() {
  if echo $STATE_LIST | grep -q $1; then
    terraform state mv -state-out=../$DESTINATION_COMPONENT/$STATE_FILE ${1//\\/} ${1//\\/};
  fi
}

function main() {
  terraform state pull > $STATE_FILE

  cd ../$SRC_COMPONENT

  terraform init

  terraform workspace select $WORKSPACE
  
  STATE_LIST=$(terraform state list)

  # mv <YOUR RESOURCE TO MOVE HERE>
  # mv <YOUR RESOURCE TO MOVE HERE>
  # ...
  
  cd ../$DESTINATION_COMPONENT

  terraform init

  terraform workspace select $WORKSPACE

  terraform state push $STATE_FILE
}

main
