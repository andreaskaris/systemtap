#!/bin/bash

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

set -eu

KERNEL_VERSION="${1-}"
if [ "${KERNEL_VERSION}" == "" ]; then
    echo "Please provide a kernel version (output of uname -r)"
    exit 1
fi
CONTAINER_IMAGE="${2-}"
if [ "${CONTAINER_IMAGE}" == "" ]; then
    echo "Please provide a valid container image name (without a tag)"
    exit 1
fi
RELEASE_VER=$(echo "${KERNEL_VERSION}" | awk -F '.' '{print $(NF-1)}' | sed 's/el//' | sed 's/_/./')

cat <<EOF > "${DIR}/_output/Dockerfile.${KERNEL_VERSION}"
FROM registry.redhat.io/rhel8/support-tools
COPY stap-scripts /stap-scripts
RUN  yum install --releasever=${RELEASE_VER} --enablerepo=rhel-8-for-x86_64-baseos-rpms \
     --enablerepo=rhel-8-for-x86_64-appstream-rpms --enablerepo=rhel-8-for-x86_64-baseos-debug-rpms \
     --enablerepo=rhel-8-for-x86_64-baseos-eus-rpms --enablerepo=rhel-8-for-x86_64-baseos-eus-debug-rpms \
     --enablerepo=rhocp-4.12-for-rhel-8-x86_64-rpms --enablerepo=rhocp-4.10-for-rhel-8-x86_64-rpms \
     --enablerepo=rhocp-4.13-for-rhel-8-x86_64-rpms --enablerepo=rhocp-4.12-for-rhel-8-x86_64-debug-rpms \
     --enablerepo=rhocp-4.10-for-rhel-8-x86_64-debug-rpms --enablerepo=rhocp-4.13-for-rhel-8-x86_64-debug-rpms \
     systemtap gcc kernel-devel-${KERNEL_VERSION} kernel-core-${KERNEL_VERSION} kernel-headers-${KERNEL_VERSION} \
     kernel-debuginfo-${KERNEL_VERSION} less -y && yum clean all
EOF

rm -Rf "${DIR}_output/stap-scripts"
cp -a stap-scripts _output/stap-scripts

pushd "${DIR}/_output"
podman build -t "${CONTAINER_IMAGE}:${KERNEL_VERSION}" -f "Dockerfile.${KERNEL_VERSION}"
podman push "${CONTAINER_IMAGE}:${KERNEL_VERSION}"
popd
