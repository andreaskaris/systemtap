#!/bin/bash

set -eu

KERNEL_VERSION="${1-}"
if [ "${KERNEL_VERSION}" == "" ]; then
    echo "Please provide a kernel version (output of uname -r)"
    exit 1
fi
CONTAINER_IMAGE="${2-}"
if [ "${CONTAINER_IMAGE}" == "" ]; then
    echo "Please provide a valid container image name"
    exit 1
fi

cat <<EOF > "Dockerfile.${KERNEL_VERSION}"
FROM registry.redhat.io/rhel8/support-tools
RUN  yum install --enablerepo=rhel-8-for-x86_64-baseos-rpms --enablerepo=rhel-8-for-x86_64-appstream-rpms \
     --enablerepo=rhel-8-for-x86_64-baseos-debug-rpms \
     systemtap gcc kernel-devel-${KERNEL_VERSION} kernel-core-${KERNEL_VERSION} kernel-headers-${KERNEL_VERSION} \
     kernel-debuginfo-${KERNEL_VERSION} -y && yum clean all
EOF
podman build -t "${CONTAINER_IMAGE}" -f "Dockerfile.${KERNEL_VERSION}"
