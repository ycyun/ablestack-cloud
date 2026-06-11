#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd -P)
PACK=${PACK:-oss}
SIMULATOR=${SIMULATOR:-default}
DISTRO=${DISTRO:-rocky9}
RELEASE=${RELEASE:-}
TEMPLATES=${TEMPLATES:-}
NODE_VERSION=${NODE_VERSION:-14.21.3}
BRAND=${BRAND:-}
PACKAGE_VERSION=${PACKAGE_VERSION:-}
TIMESTAMP_VALUE=${TIMESTAMP_VALUE:-}
BUILD_SRPM=${BUILD_SRPM:-false}
USE_TIMESTAMP=${USE_TIMESTAMP:-false}
LOCAL_FAST=${LOCAL_FAST:-false}

if ! command -v dnf >/dev/null 2>&1; then
    echo "This helper must run inside a Rocky/RHEL-compatible environment with dnf."
    exit 1
fi

if [ "$DISTRO" != "rocky9" ] && [ "$DISTRO" != "centos8" ]; then
    echo "Unsupported DISTRO=$DISTRO. Expected rocky9 or centos8."
    exit 1
fi

echo "== Rocky 9.7 RPM build helper =="
echo "ROOT_DIR=$ROOT_DIR"
echo "DISTRO=$DISTRO"
echo "PACK=$PACK"
echo "SIMULATOR=$SIMULATOR"
echo "RELEASE=${RELEASE:-<default>}"
echo "TEMPLATES=${TEMPLATES:-<none>}"
echo "NODE_VERSION=$NODE_VERSION"
echo "BRAND=${BRAND:-<default>}"
echo "PACKAGE_VERSION=${PACKAGE_VERSION:-<maven>}"
echo "TIMESTAMP_VALUE=${TIMESTAMP_VALUE:-<generated>}"
echo "BUILD_SRPM=$BUILD_SRPM"
echo "USE_TIMESTAMP=$USE_TIMESTAMP"
echo "LOCAL_FAST=$LOCAL_FAST"

configure_rocky97_vault_repos() {
    local repo_file=""
    local candidate=""
    local tmp_file=""

    for candidate in /etc/yum.repos.d/*.repo; do
        [ -e "$candidate" ] || continue
        if grep -Eq '^\[(baseos|baseos-debuginfo|baseos-source|appstream|appstream-debuginfo|appstream-source|crb|crb-debuginfo|crb-source|extras|extras-debuginfo|extras-source)\]' "$candidate"; then
            repo_file="$candidate"
            break
        fi
    done

    if [ -z "$repo_file" ]; then
        echo "Unable to find a Rocky repo file under /etc/yum.repos.d."
        echo "Available repo files:"
        ls -1 /etc/yum.repos.d/*.repo 2>/dev/null || true
        exit 1
    fi

    tmp_file=$(mktemp)

    awk -v vault_root="https://dl.rockylinux.org/vault/rocky/9.7" '
        function desired_baseurl(section) {
            if (section == "baseos") return vault_root "/BaseOS/$basearch/os/"
            if (section == "baseos-debuginfo") return vault_root "/BaseOS/$basearch/debug/tree/"
            if (section == "baseos-source") return vault_root "/BaseOS/source/tree/"
            if (section == "appstream") return vault_root "/AppStream/$basearch/os/"
            if (section == "appstream-debuginfo") return vault_root "/AppStream/$basearch/debug/tree/"
            if (section == "appstream-source") return vault_root "/AppStream/source/tree/"
            if (section == "crb") return vault_root "/CRB/$basearch/os/"
            if (section == "crb-debuginfo") return vault_root "/CRB/$basearch/debug/tree/"
            if (section == "crb-source") return vault_root "/CRB/source/tree/"
            if (section == "extras") return vault_root "/extras/$basearch/os/"
            if (section == "extras-debuginfo") return vault_root "/extras/$basearch/debug/tree/"
            if (section == "extras-source") return vault_root "/extras/source/tree/"
            return ""
        }

        function is_target(section) {
            return desired_baseurl(section) != ""
        }

        /^\[[^]]+\]$/ {
            section = substr($0, 2, length($0) - 2)
            print
            next
        }

        {
            if (is_target(section)) {
                if ($0 ~ /^mirrorlist=/) {
                    print "#" $0
                    next
                }
                if ($0 ~ /^#?baseurl=/) {
                    print "baseurl=" desired_baseurl(section)
                    next
                }
            }

            print
        }
    ' "$repo_file" >"$tmp_file"

    cat "$tmp_file" >"$repo_file"
    rm -f "$tmp_file"

    if ! grep -qF 'baseurl=https://dl.rockylinux.org/vault/rocky/9.7/BaseOS/$basearch/os/' "$repo_file"; then
        echo "Rocky 9.7 BaseOS vault URL is missing from $repo_file"
        exit 1
    fi

    if ! grep -qF 'baseurl=https://dl.rockylinux.org/vault/rocky/9.7/AppStream/$basearch/os/' "$repo_file"; then
        echo "Rocky 9.7 AppStream vault URL is missing from $repo_file"
        exit 1
    fi

    if ! grep -qF 'baseurl=https://dl.rockylinux.org/vault/rocky/9.7/CRB/$basearch/os/' "$repo_file"; then
        echo "Rocky 9.7 CRB vault URL is missing from $repo_file"
        exit 1
    fi

    if ! grep -qF 'baseurl=https://dl.rockylinux.org/vault/rocky/9.7/extras/$basearch/os/' "$repo_file"; then
        echo "Rocky 9.7 extras vault URL is missing from $repo_file"
        exit 1
    fi

    if awk '
        function is_target(section) {
            return section ~ /^(baseos|baseos-debuginfo|baseos-source|appstream|appstream-debuginfo|appstream-source|crb|crb-debuginfo|crb-source|extras|extras-debuginfo|extras-source)$/
        }

        /^\[[^]]+\]$/ {
            section = substr($0, 2, length($0) - 2)
            next
        }

        is_target(section) && $0 ~ /^mirrorlist=/ {
            bad = 1
        }

        END {
            exit bad
        }
    ' "$repo_file"; then
        :
    else
        echo "Rocky 9.7 repo file still contains active mirrorlist entries: $repo_file"
        exit 1
    fi

    echo "Rocky 9.7 repository configuration rewritten to vault:"
    awk '
        function is_target(section) {
            return section ~ /^(baseos|baseos-debuginfo|baseos-source|appstream|appstream-debuginfo|appstream-source|crb|crb-debuginfo|crb-source|extras|extras-debuginfo|extras-source)$/
        }

        /^\[[^]]+\]$/ {
            section = substr($0, 2, length($0) - 2)
            show = is_target(section)
            if (show) {
                print
            }
            next
        }

        show && (/^#?mirrorlist=/ || /^baseurl=/) {
            print
        }
    ' "$repo_file"
}

configure_rocky97_vault_repos

dnf clean all

DNF=(dnf --releasever=9.7 -y)

"${DNF[@]}" install dnf-plugins-core
dnf --releasever=9.7 config-manager --set-enabled crb || true
"${DNF[@]}" install epel-release || true
"${DNF[@]}" install \
    bash \
    bzip2 \
    ca-certificates \
    findutils \
    gcc \
    genisoimage \
    git \
    glibc-devel \
    gzip \
    java-11-openjdk-devel \
    java-17-openjdk-devel \
    jq \
    maven \
    nodejs \
    openssl-devel \
    python3-devel \
    python3-pip \
    python3-setuptools \
    rpm-build \
    systemd-rpm-macros \
    shadow-utils \
    tar \
    unzip \
    wget \
    which \
    xz

if [ "$PACK" = "noredist" ] || [ "$PACK" = "NOREDIST" ]; then
    echo "Installing non-redistributable VMware build dependencies"
    tmp_nonoss_dir=$(mktemp -d /tmp/cloudstack-nonoss-XXXXXX)
    git clone --depth 1 https://github.com/shapeblue/cloudstack-nonoss.git "$tmp_nonoss_dir"
    (
        cd "$tmp_nonoss_dir"
        bash -x install-non-oss.sh
    )
    rm -rf "$tmp_nonoss_dir"
fi

if [ ! -x "/opt/node-v${NODE_VERSION}-linux-x64/bin/node" ]; then
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
        | tar -xJf - -C /opt
fi

JAVA17_HOME=$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")
if [ -d /usr/lib/jvm/java-17-openjdk ]; then
    JAVA17_HOME=/usr/lib/jvm/java-17-openjdk
fi

export JAVA_HOME="$JAVA17_HOME"
export PATH="/opt/node-v${NODE_VERSION}-linux-x64/bin:$JAVA_HOME/bin:$PATH"
export MAVEN_OPTS="${MAVEN_OPTS:+$MAVEN_OPTS }-Dcom.sun.xml.bind.v2.bytecode.ClassTailor.noOptimize=true --add-opens=java.base/java.lang=ALL-UNNAMED"

git config --global --add safe.directory "$ROOT_DIR"

mkdir -p "$ROOT_DIR/dist/rocky97-build"
{
    echo "date=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "os_release=$(tr '\n' ' ' </etc/os-release)"
    echo "java_version=$("$JAVA_HOME/bin/java" -version 2>&1 | tr '\n' ' ' )"
    echo "maven_version=$(mvn -v | head -n 1)"
    echo "maven_opts=$MAVEN_OPTS"
    echo "node_version=$(node -v)"
    echo "npm_version=$(npm -v)"
    echo "pack=$PACK"
    echo "simulator=$SIMULATOR"
    echo "distro=$DISTRO"
    echo "release=${RELEASE:-<default>}"
    echo "templates=${TEMPLATES:-<none>}"
    echo "brand=${BRAND:-<default>}"
    echo "package_version=${PACKAGE_VERSION:-<maven>}"
    echo "timestamp_value=${TIMESTAMP_VALUE:-<generated>}"
    echo "build_srpm=$BUILD_SRPM"
    echo "use_timestamp=$USE_TIMESTAMP"
    echo "local_fast=$LOCAL_FAST"
} >"$ROOT_DIR/dist/rocky97-build/environment.txt"

build_args=(
    --distribution "$DISTRO"
    --pack "$PACK"
)

if [ "$SIMULATOR" != "default" ]; then
    build_args+=(--simulator "$SIMULATOR")
fi

if [ -n "$RELEASE" ]; then
    build_args+=(--release "$RELEASE")
fi

if [ -n "$BRAND" ]; then
    build_args+=(--brand "$BRAND")
fi

if [ -n "$PACKAGE_VERSION" ]; then
    build_args+=(--package-version "$PACKAGE_VERSION")
fi

if [ -n "$TIMESTAMP_VALUE" ]; then
    build_args+=(--timestamp-value "$TIMESTAMP_VALUE")
fi

if [ -n "$TEMPLATES" ]; then
    build_args+=(--templates "$TEMPLATES")
fi

if [ "$USE_TIMESTAMP" == "true" ] || [ -n "$TIMESTAMP_VALUE" ]; then
    build_args+=(--use-timestamp)
fi

if [ "$BUILD_SRPM" == "true" ]; then
    build_args+=(--build-srpm)
fi

if [ "$LOCAL_FAST" == "true" ]; then
    build_args+=(--local-fast)
fi

cd "$ROOT_DIR/packaging"
./package.sh "${build_args[@]}"

cd "$ROOT_DIR"
find dist/rpmbuild -type f \( -name '*.rpm' -o -name '*.src.rpm' \) | sort \
    > dist/rocky97-build/artifacts.txt
