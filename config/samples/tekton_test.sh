#!/bin/bash
#
# Copyright contributors to the Kubebb Core project
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
# 	  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
if [[ $RUNNER_DEBUG -eq 1 ]] || [[ $GITHUB_RUN_ATTEMPT -gt 1 ]]; then
	# use [debug logging](https://docs.github.com/en/actions/monitoring-and-troubleshooting-workflows/enabling-debug-logging)
	# or run the same test multiple times.
	set -x
fi
export TERM=xterm-color

KindName="kubebb-core"
TimeoutSeconds=${TimeoutSeconds:-"300"}
HelmTimeout=${HelmTimeout:-"1800s"}
KindVersion=${KindVersion:-"v1.24.4"}
TempFilePath=${TempFilePath:-"/tmp/kubebb-core-tekton-test"}
KindConfigPath=${TempFilePath}/kind-config.yaml
InstallDirPath=${TempFilePath}/building-base
DefaultPassWord=${DefaultPassWord:-'passw0rd'}
LOG_DIR=${LOG_DIR:-"/tmp/kubebb-core-tekton-test/logs"}
RootPath=$(dirname -- "$(readlink -f -- "$0")")/../..

Timeout="${TimeoutSeconds}s"
mkdir ${TempFilePath} || true

function debugInfo {
	if [[ $? -eq 0 ]]; then
		exit 0
	fi
	if [[ $debug -ne 0 ]]; then
		exit 1
	fi

	warning "debugInfo start 🧐"
	mkdir -p $LOG_DIR

	warning "1. Try to get all resources "
	kubectl api-resources --verbs=list -o name | xargs -n 1 kubectl get -A --ignore-not-found=true --show-kind=true >$LOG_DIR/get-all-resources-list.log
	kubectl api-resources --verbs=list -o name | xargs -n 1 kubectl get -A -oyaml --ignore-not-found=true --show-kind=true >$LOG_DIR/get-all-resources-yaml.log

	warning "2. Try to describe all resources "
	kubectl api-resources --verbs=list -o name | xargs -n 1 kubectl describe -A >$LOG_DIR/describe-all-resources.log

	warning "3. Try to export kind logs to $LOG_DIR..."
	kind export logs --name=${KindName} $LOG_DIR
	sudo chown -R $USER:$USER $LOG_DIR

	warning "debugInfo finished ! "
	warning "This means that some tests have failed. Please check the log. 🌚"
	debug=1
	exit 1
}
trap 'debugInfo $LINENO' ERR
trap 'debugInfo $LINENO' EXIT
debug=0

function cecho() {
	declare -A colors
	colors=(
		['black']='\E[0;47m'
		['red']='\E[0;31m'
		['green']='\E[0;32m'
		['yellow']='\E[0;33m'
		['blue']='\E[0;34m'
		['magenta']='\E[0;35m'
		['cyan']='\E[0;36m'
		['white']='\E[0;37m'
	)
	local defaultMSG="No message passed."
	local defaultColor="black"
	local defaultNewLine=true
	while [[ $# -gt 1 ]]; do
		key="$1"
		case $key in
		-c | --color)
			color="$2"
			shift
			;;
		-n | --noline)
			newLine=false
			;;
		*)
			# unknown option
			;;
		esac
		shift
	done
	message=${1:-$defaultMSG}     # Defaults to default message.
	color=${color:-$defaultColor} # Defaults to default color, if not specified.
	newLine=${newLine:-$defaultNewLine}
	echo -en "${colors[$color]}"
	echo -en "$message"
	if [ "$newLine" = true ]; then
		echo
	fi
	tput sgr0 #  Reset text attributes to normal without clearing screen.
	return
}

function warning() {
	cecho -c 'yellow' "$@"
}

function error() {
	cecho -c 'red' "$@"
}

function info() {
	cecho -c 'blue' "$@"
}

function waitComponentStatus() {
	namespace=$1
	componentName=$2
	START_TIME=$(date +%s)
	while true; do
		versions=$(kubectl -n${namespace} get components.core.kubebb.k8s.com.cn ${componentName} -ojson --ignore-not-found=true | jq -r '.status.versions|length')
		if [[ $versions -ne 0 ]]; then
			echo "component ${componentName} already have version information and can be installed"
			break
		fi
		CURRENT_TIME=$(date +%s)
		ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
		if [ $ELAPSED_TIME -gt $TimeoutSeconds ]; then
			error "Timeout reached"
			exit 1
		fi
		sleep 5
	done
}

function waitRatingDone() {
	namespace=$1
	ratingName=$2
	START_TIME=$(date +%s)
	sleep 2 # wait for operator patch status. avoid 0=0 situations
	while true; do
		complete=$(kubectl -n${namespace} get rating ${ratingName} -ojson --ignore-not-found=true | jq '.status.pipelineRuns' | jq '{l:length,o:map(select(.conditions[0].type=="Succeeded" and .conditions[0].status=="True"))|length}' | jq '.l == .o')
		if [[ $complete == "true" ]]; then
			echo "rating ${ratingName} task completed"
			break
		fi
		CURRENT_TIME=$(date +%s)
		ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
		if [ $ELAPSED_TIME -gt $TimeoutSeconds ]; then
			error "Timeout reached"
			exit 1
		fi
		sleep 5
	done
}

function checkCm() {
	namespace=$1
	cmname=$2
	START_TIME=$(date +%s)
	while true; do
		cm=$(kubectl -n${namespace} get cm ${cmname} -ojson --ignore-not-found=true | jq -r '.metadata.name')
		if [[ ${cm} == ${cmname} ]]; then
			echo "configmap ${cmname} has been created."
			break
		fi
		CURRENT_TIME=$(date +%s)
		ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
		if [ $ELAPSED_TIME -gt $TimeoutSeconds ]; then
			error "Timeout reached"
			exit 1
		fi
		sleep 5
	done

}

info "1. create kind cluster"
make kind

info "2. install tekton operator"
helm repo add kubebb https://kubebb.github.io/components
helm repo update kubebb
kubectl create ns tekton
helm -ntekton install tekton kubebb/tekton-operator --version 0.64.0 --wait
# install certmanager
helm repo add --force-update jetstack https://charts.jetstack.io
helm repo update jetstack
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace \
	--version v1.12.0 \
	--set prometheus.enabled=false \
	--set installCRDs=true

info "2.2 deploy kubebb/core"
docker tag kubebb/core:latest kubebb/core:example-e2e
kind load docker-image kubebb/core:example-e2e --name=$KindName
make deploy IMG="kubebb/core:example-e2e"
kubectl wait deploy -n kubebb-system kubebb-controller-manager --for condition=Available=True

info "2.3 enable rating -- create clusterrole rating-clusterrole"
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: rating-clusterrole
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["*"]
EOF

info "2.4 enable rating -- crate clusterrolebinding rating-clusterrolebinding"
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: rating-clusterrolebinding
roleRef:
  kind: ClusterRole
  name: rating-clusterrole
  apiGroup: rbac.authorization.k8s.io
EOF

info "2.5 enable rating -- patch kubebb-controller-manager deployment"
cat <<EOF >patch.yaml
spec:
  template:
    spec:
      containers:
      - name: manager
        env:
        - name: RATING_ENABLE  
          value: "true"
        - name: RATING_SERVICEACCOUNT 
          value: rating-serviceaccount
        - name: RATING_CLUSTERROLE
          value: rating-clusterrole
        - name: RATING_CLUSTERROLEBINDING
          value: rating-clusterrolebinding
EOF

kubectl -nkubebb-system patch deployment kubebb-controller-manager --patch-file patch.yaml
kubectl wait deploy -n kubebb-system kubebb-controller-manager --for condition=Available=True

info "3 create tasks and pipeline"

info "3.1 craete task rback"
kubectl apply -f config/samples/task-rback.yaml

info "3.2 create task helm-lint"
kubectl apply -f config/samples/task-helm-lint.yaml

info "3.3 create pipeline rback-helm-lint-pipeline"
kubectl apply -f config/samples/pipeline-rback-helm-lint.yaml

info "3.4 create pipline only-rback-pipeline"
kubectl apply -f config/samples/pipeline-rback.yaml

info "3.5 create pipeline only-helm-lint-pipeline"
kubectl apply -f config/samples/pipeline-helm-lint.yaml

info "3.6 add kubebb repository"
kubectl apply -f config/samples/core_v1alpha1_repository_kubebb.yaml
waitComponentStatus "kubebb-system" "repository-kubebb.kubebb-core"

info "4 create rating with one pipline"
kubectl apply -f config/samples/core_v1alpha1_rating_1.yaml
waitRatingDone "kubebb-system" "one-pipeline-rating"
checkCm "kubebb-system" "repository-kubebb.kubebb-core.v0.1.10"

info "5 create rating with two pipeline"
kubectl apply -f config/samples/core_v1alpha1_rating_2.yaml
waitRatingDone "kubebb-system" "two-pipeline-rating"
checkCm "kubebb-system" "repository-kubebb.kubebb-core.v0.1.10"

info "all finished! ✅"
