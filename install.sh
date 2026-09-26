#!/bin/sh
set -e

SOURCE_URL="https://raw.githubusercontent.com/kiammota/wcp/main/wcp.sh"
INSTALL_NAME="wcp"

echo "Install wcp globally? [y/N]"
read -r answer

case "$answer" in
    y|Y)
        INSTALL_DIR="/usr/local/bin"
        NEED_SUDO=1
        ;;
    *)
        INSTALL_DIR="$HOME/.local/bin"
        NEED_SUDO=0
        ;;
esac

# Cria o diretório se necessário
if [ "$NEED_SUDO" -eq 1 ]; then
    if [ ! -d "$INSTALL_DIR" ]; then
        echo "Creating $INSTALL_DIR (requires sudo)..."
        sudo mkdir -p "$INSTALL_DIR"
    fi
else
    mkdir -p "$INSTALL_DIR"
fi

TMP_FILE=$(mktemp)

cleanup() {
    rm -f "$TMP_FILE"
}
trap cleanup EXIT

echo "Downloading wcp..."
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$SOURCE_URL" -o "$TMP_FILE"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$SOURCE_URL" -O "$TMP_FILE"
else
    echo "Error: curl or wget is required." >&2
    exit 1
fi

# Verifica se o download parece ser um script válido
if ! head -n 1 "$TMP_FILE" | grep -q '^#!/'; then
    echo "Error: downloaded file does not look like a valid shell script." >&2
    exit 1
fi

chmod +x "$TMP_FILE"

if [ "$NEED_SUDO" -eq 1 ]; then
    echo "Installing to $INSTALL_DIR (requires sudo)..."
    sudo mv "$TMP_FILE" "$INSTALL_DIR/$INSTALL_NAME"
    sudo chmod +x "$INSTALL_DIR/$INSTALL_NAME"
else
    mv "$TMP_FILE" "$INSTALL_DIR/$INSTALL_NAME"
fi

# Garante que ~/.local/bin está no PATH (aviso apenas)
if [ "$NEED_SUDO" -eq 0 ]; then
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *)
            echo ""
            echo "Note: $HOME/.local/bin is not in your PATH."
            echo "Add this line to your ~/.bashrc or ~/.zshrc:"
            echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
            echo ""
            ;;
    esac
fi

echo "wcp installed successfully at $INSTALL_DIR/$INSTALL_NAME"
echo "Try: wcp --help   or   wcp arquivo.mp4"
