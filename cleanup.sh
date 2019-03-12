#!/bin/sh
#
# Copyright (c) 2019 by SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the LICENSE file
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

delete_expired_serviceaccounts () {
  TYPE=$1
  echo "Looking for expired dashboard terminal serviceaccounts of type ${TYPE}.."

  SERVICEACCOUNTS="$(kubectl get serviceaccounts --selector=component=dashboard-terminal,saType=${TYPE} --all-namespaces -ojson)"
  SERVICEACCOUNTS_COUNT="$(echo ${SERVICEACCOUNTS} | jq .items | jq length)"

  echo "Found ${SERVICEACCOUNTS_COUNT} dashboard terminal service accounts of type ${TYPE}"
  COUNT=0
  while [ "${COUNT}" -lt "${SERVICEACCOUNTS_COUNT}" ]
  do
    SERVICEACCOUNT="$(echo ${SERVICEACCOUNTS} | jq .items[${COUNT}])"
    SA_NAME="$(echo ${SERVICEACCOUNT} | jq -r .metadata.name)"
    SA_NAMESPACE="$(echo ${SERVICEACCOUNT} | jq -r .metadata.namespace)"
    SA_HEARTBEAT="$(echo ${SERVICEACCOUNT} | jq -r .metadata.annotations[\"garden.sapcloud.io/terminal-heartbeat\"])"

    if [ ! -z "${SA_NAME}" ] && [ ! -z "${SA_NAMESPACE}" ]; then

      let SA_SECS_WO_HEARTBEAT="${CURRENT_TIMESTAMP}-${SA_HEARTBEAT}"
      echo "Checking serviceaccount ${SA_NAMESPACE}/${SA_NAME}: ${SA_SECS_WO_HEARTBEAT}s since last heartbeat"

      if [ "${SA_SECS_WO_HEARTBEAT}" -gt "${THRESHOLD}" ]; then
        echo "Did not receive heartbeat signal within ${THRESHOLD} seconds. Deleting serviceaccount ${SA_NAMESPACE}/${SA_NAME}"
        kubectl delete serviceaccount ${SA_NAME} -n ${SA_NAMESPACE}
      fi
    fi
    COUNT=$((${COUNT}+1))
  done
}

THRESHOLD=${NO_HEARTBEAT_DELETE_SECONDS:-86400}
CURRENT_TIMESTAMP="$(date +%s)"

echo "Configured max lifetime without heartbeat: ${THRESHOLD}s"

if [ -e /config/attach/config ]; then
  export KUBECONFIG=/config/attach/config
  delete_expired_serviceaccounts attach
fi
if [ -e /config/access/config ]; then
  export KUBECONFIG=/config/access/config
  delete_expired_serviceaccounts access
fi
