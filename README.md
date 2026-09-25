# wcp

A small command-line utility for copying files and command output directly to the Wayland clipboard.

`wcp` lets you copy files or pipe command output to your clipboard without leaving the terminal.

```bash
wcp file.txt
```

```bash
git diff | wcp
```

```bash
cat README.md | wcp
```

## Features

* Copy files to the Wayland clipboard
* Copy text from `stdin`
* Support multiple files
* Works with shell pipelines
* Uses `wl-copy` from `wl-clipboard`
* No configuration required

## Requirements

* Linux
* Wayland
* `wl-clipboard`

## Installation

Install `wcp` with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/kiammota/wcp/main/install.sh | sh
```

The installer will ask whether you want a local or global installation.

A local installation places `wcp` in:

```text
~/.local/bin/wcp
```

A global installation places it in:

```text
/usr/local/bin/wcp
```

The installer handles permissions and installation automatically.

After installation, simply run:

```bash
wcp
```

## Usage

Copy a file:

```bash
wcp file.txt
```

Copy multiple files:

```bash
wcp file.txt image.png document.pdf
```

Copy command output:

```bash
ls -la | wcp
```

Copy Git output:

```bash
git diff | wcp
```

Copy the contents of a file:

```bash
cat README.md | wcp
```

## How it works

When files are passed as arguments, `wcp` copies them to the Wayland clipboard as file URIs. Compatible applications can then paste the actual files.

When data is received through `stdin`, `wcp` copies it as text.

```text
file(s) ──────→ wcp ──────→ Wayland clipboard
                              ↓
stdin ─────────→ wcp ──────→ Wayland clipboard
```

## License

MIT
