#!/bin/sh

set -e

SOURCE="wcp.sh"

if [ ! -f "$SOURCE" ]; then
    echo "Error: $SOURCE not found."
    exit 1
fi

echo "Where do you want to install wcp?"
echo "1) Local   (~/.local/bin)"
echo "2) Global  (/usr/local/bin)"
printf "Choose [1/2]: "

read choice

case "$choice" in
    1)
        INSTALL_DIR="$HOME/.local/bin"
        ;;
    2)
        INSTALL_DIR="/usr/local/bin"

        if [ "$(id -u)" -ne 0 ]; then
            SUDO="sudo"
        fi
        ;;
    *)
        echo "Invalid choice."
        exit 1
        ;;
esac

if [ -n "${SUDO:-}" ]; then
    $SUDO mkdir -p "$INSTALL_DIR"
    $SUDO cp "$SOURCE" "$INSTALL_DIR/wcp"
    $SUDO chmod +x "$INSTALL_DIR/wcp"
else
    mkdir -p "$INSTALL_DIR"
    cp "$SOURCE" "$INSTALL_DIR/wcp"
    chmod +x "$INSTALL_DIR/wcp"
fi

echo "wcp installed successfully."
echo "Location: $INSTALL_DIR/wcp"
