#!/bin/sh
if [ ! -t 0 ]; then
    wl-copy
    exit $?
fi

if [ "$#" -lt 1 ]; then
    echo "Usage: wcp <file1> [file2 ...]" >&2
    exit 1
fi

if [ "$(uname -s)" != "Linux" ]; then
    echo "Error: wcp requires Linux." >&2
    exit 1
fi

if [ -z "$WAYLAND_DISPLAY" ]; then
    echo "Error: Wayland environment not detected." >&2
    exit 1
fi

if ! command -v wl-copy >/dev/null 2>&1; then
    echo "Error: wl-copy was not found." >&2
    echo "Make sure the 'wl-clipboard' package is installed." >&2
    exit 1
fi

for file in "$@"; do
    if [ ! -e "$file" ]; then
        echo "Error: file does not exist: $file" >&2
        exit 1
    fi

    realpath "$file"
done | sed 's|^|file://|' | wl-copy -t text/uri-list
