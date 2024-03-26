#! /bin/bash

# usage ./remoteStateMigration.sh path/to/source/configs path/to/dest/configs source.resource.to.migrate dest.to.place.resource

PATH_TO_SOURCE_TF_CONFIG=$1
PATH_TO_DEST_TF_CONFIG=$2

SOURCE_TF_RESOURCE=$3
DEST_TF_RESOURCE=$4

COPY_ONLY=$5

TMP_DIR="tmp_tf_state_refactor"

mkdir ${TMP_DIR}

echo "initializing terraform"
terraform -chdir="${PATH_TO_SOURCE_TF_CONFIG}" init
terraform -chdir="${PATH_TO_DEST_TF_CONFIG}" init

SOURCE_STATE_FILE="${TMP_DIR}/source_state.tfstate"
DEST_STATE_FILE="${TMP_DIR}/source_state.tfstate"

echo "pulling state files"
terraform -chdir="${PATH_TO_SOURCE_TF_CONFIG}" state pull > ${SOURCE_STATE_FILE}
terraform -chdir="${PATH_TO_DEST_TF_CONFIG}" state pull > ${DEST_STATE_FILE}
cp -r ${TMP_DIR} backups


echo "moving state files"
terraform state mv -state=${SOURCE_STATE_FILE} -state-out=${DEST_STATE_FILE} ${SOURCE_TF_RESOURCE} ${DEST_TF_RESOURCE}

echo "pushing new state"

read -p "Confirm, Push the modified source state? (only 'yes' will confirm) " -r
if [ "${REPLY}" == "yes" ];
then
  terraform -chdir="${PATH_TO_SOURCE_TF_CONFIG}" state push ${SOURCE_STATE_FILE}
fi

read -p "Confirm, Push the modified dest state? (only 'yes' will confirm) " -r
if [ "${REPLY}" == "yes" ];
then
terraform -chdir="${PATH_TO_DEST_TF_CONFIG}" state push ${DEST_STATE_FILE}
fi

rm -r ${TMP_DIR}

echo "DONE"
