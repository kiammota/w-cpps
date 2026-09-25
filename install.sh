#!/bin/sh

set -e

SOURCE_URL="https://raw.githubusercontent.com/kiammota/wcp/main/wcp.sh"
INSTALL_NAME="wcp"

echo "Install wcp globally? [y/N]"
read answer

case "$answer" in
    y|Y)
        INSTALL_DIR="/usr/local/bin"
        ;;
    *)
        INSTALL_DIR="$HOME/.local/bin"
        ;;
esac

mkdir -p "$INSTALL_DIR"

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$SOURCE_URL" -o "$INSTALL_DIR/$INSTALL_NAME"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$SOURCE_URL" -O "$INSTALL_DIR/$INSTALL_NAME"
else
    echo "Error: curl or wget is required."
    exit 1
fi

chmod +x "$INSTALL_DIR/$INSTALL_NAME"

echo "wcp installed successfully at $INSTALL_DIR/$INSTALL_NAME"
