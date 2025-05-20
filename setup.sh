#!/usr/bin/env bash

set -euo pipefail

# ---- Metadata ----
echo "MPC Project Build Environment Setup"
echo "Version: 1.0"
echo "Description: Installs Go 1.23, LLVM 20, OpenSSL (custom), and build tools."

# ---- Environment Variables ----
export CGO_ENABLED=0
export CC=/usr/bin/clang-20
export CXX=/usr/bin/clang++-20

# ---- Update and Install System Packages ----
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    wget \
    rsync \
    gnupg \
    ca-certificates \
    lsb-release \
    cmake \
    libssl-dev

# ---- Install Go 1.23 ----
GO_VERSION="1.23.0"
if ! command -v go >/dev/null 2>&1 || [[ "$(go version | awk '{print $3}')" != "go${GO_VERSION}" ]]; then
    echo "Installing Go ${GO_VERSION}..."
    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    rm "go${GO_VERSION}.linux-amd64.tar.gz"
    export PATH="/usr/local/go/bin:$PATH"
    echo 'export PATH="/usr/local/go/bin:$PATH"' >> ~/.profile
fi

# ---- Add LLVM 20 Repository and Install Tools ----
sudo wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/llvm-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/llvm-archive-keyring.gpg] http://apt.llvm.org/$(lsb_release -cs)/ llvm-toolchain-$(lsb_release -cs)-20 main" | sudo tee /etc/apt/sources.list.d/llvm20.list
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    clang-20 \
    clang-format-20 \
    lld-20 \
    libfuzzer-20-dev \
    libclang-rt-20-dev

sudo update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-20 100

# ---- Build and Install Tweaked OpenSSL ----
WORK_DIR="/tmp/build_openssl"
OPENSSL_SCRIPT="build-static-openssl-linux.sh"
OPENSSL_PATH="/usr/local/opt/openssl@3.2.0"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Place your build-static-openssl-linux.sh script here or download it
# Example: wget https://yourdomain/scripts/openssl/build-static-openssl-linux.sh
if [[ ! -f $OPENSSL_SCRIPT ]]; then
    echo "Please place $OPENSSL_SCRIPT in $WORK_DIR before running this script."
    exit 1
fi

chmod +x "$OPENSSL_SCRIPT"
./"$OPENSSL_SCRIPT"

sudo mkdir -p /usr/local/lib64 /usr/local/lib /usr/local/include
sudo ln -sf "$OPENSSL_PATH/lib64/libcrypto.a" /usr/local/lib64/libcrypto.a
sudo ln -sf "$OPENSSL_PATH/lib64/libcrypto.a" /usr/local/lib/libcrypto.a
sudo ln -sf "$OPENSSL_PATH/include/openssl" /usr/local/include/openssl

cd ~
rm -rf "$WORK_DIR"

echo "Build environment setup complete!"
