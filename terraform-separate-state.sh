#!/bin/bash -ex
ENV=staging
for resource in `terraform state list -state=terraform.tfstate |grep $ENV`
do
    echo $resource
    terraform state mv -state=terraform.tfstate -state-out="$ENV-test.tfstate" $resource $resource
done
# rm *.backup
