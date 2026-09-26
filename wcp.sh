#!/bin/sh
# wcp - copy file(s) as file:// URIs to Wayland clipboard (text/uri-list)
# Optimized for pasting into browsers / file upload fields.

set -eu

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

usage() {
    printf 'Usage: %s <file1> [file2 ...]\n' "${0##*/}" >&2
    printf '       %s < file   (or pipe content)\n' "${0##*/}" >&2
    exit 1
}

# Convert absolute path → properly percent-encoded file:// URI
# Uses Python for correct RFC 3986 / file-URI encoding (handles Unicode, spaces, etc.)
path_to_uri() {
    path="$1"
    if command -v python3 >/dev/null 2>&1; then
        python3 -c '
import sys, urllib.request, pathlib
p = pathlib.Path(sys.argv[1]).resolve()
print(p.as_uri())
' "$path"
    else
        # Fallback (no percent-encoding of special chars – works for simple ASCII paths)
        printf 'file://%s\n' "$path"
    fi
}

# ---- main ----

# Piped / non-TTY input → just forward to wl-copy (original behaviour)
if [ ! -t 0 ]; then
    exec wl-copy
fi

[ "$#" -ge 1 ] || usage

# Platform checks
[ "$(uname -s)" = "Linux" ] || die "wcp requires Linux."
[ -n "${WAYLAND_DISPLAY:-}" ] || die "Wayland environment not detected (WAYLAND_DISPLAY is empty)."
command -v wl-copy >/dev/null 2>&1 || {
    die "wl-copy not found. Install the 'wl-clipboard' package."
}

# Build the uri-list
uri_list=""
count=0

for file in "$@"; do
    if [ ! -e "$file" ]; then
        die "file does not exist: $file"
    fi

    # realpath resolves symlinks and makes absolute
    abs=$(realpath "$file") || die "cannot resolve path: $file"

    uri=$(path_to_uri "$abs")

    if [ -z "$uri_list" ]; then
        uri_list="$uri"
    else
        # RFC 2483 recommends \r\n
        uri_list="${uri_list}$(printf '\r\n')${uri}"
    fi
    count=$((count + 1))
done

# Copy as text/uri-list (this is what browsers / file managers expect)
printf '%s' "$uri_list" | wl-copy -t text/uri-list

printf '%d file(s) copied to clipboard as text/uri-list\n' "$count" >&2
