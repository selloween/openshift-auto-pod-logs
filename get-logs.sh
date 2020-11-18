#!/bin/bash
source "/opt/ocp/logs/${1}-token.sh"

if [ -f "/opt/ocp/logs/${1}-token.sh" ]; then
  echo "Token exists"
else
  echo "Token /opt/ocp/logs/${1}-token.sh is missing!"
  exit 1
fi

OC_PROJECT=$1
BASE_DIR="/opt/ocp/logs"
TAR="${OC_PROJECT}-logs.tar.gz"
SSH_HOST=""
SSH_USER=""
SSH_KEY="/home/${SSH_USER}/.ssh/id_rsa"
SSH_HOST_DIR="/opt/ocp-logs"

cd $BASE_DIR
if [ -d "$BASE_DIR" ]; then
  rm -rf $OC_PROJECT && mkdir $OC_PROJECT
fi

if [ -f "$TAR" ]; then
  rm -f $TAR
fi

oc login --token=$TOKEN
oc project $OC_PROJECT

SERVICE_ACCOUNT=`oc whoami`
echo "###############################"
echo "OC Project is ${OC_PROJECT}"
echo "OC Service Account is ${SERVICE_ACCOUNT}"
echo "###############################"
echo " "
echo "Generating Logs..."

oc get pods | awk 'NR>1 { print $1 }' | xargs -L1 -I {} sh -c 'oc logs $1 >> "./${OC_PROJECT}/${1}.log"' -- {}
oc get pods | awk 'NR>1 { print $1 }' | xargs -L1 -I {} sh -c 'oc describe pod/$1 >> "./${OC_PROJECT}/${1}.describe.log"' -- {}

tar -czvPf $TAR ./$OC_PROJECT && \
chown ansible:ansible $TAR && \

echo "Copying ${TAR} to ${SSH_HOST}"
su - ${SSH_USER} -c "scp  -i ${SSH_KEY} ${BASE_DIR}/${TAR} ${SSH_USER}@${SSH_HOST}:${SSH_HOST_DIR}" && \
echo "Finished"
exit
