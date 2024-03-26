#!/usr/bin/env bash

# Credits to https://gist.github.com/nathan-muir/9c81eeaed9200d367ab227ccef13b602

# Get a local copy of the destination project state
cd project_dest
terraform state pull > remote.tfstate

# Move from the SRC project to the DEST project
cd ../project_src
terraform state mv \
  -state-out=../project_dest/remote.tfstate \
  module.XYZ module.XYZ

# Push the local file to your remote backend (eg S3)
cd ../project_dest
terraform state push remote.tfstate
