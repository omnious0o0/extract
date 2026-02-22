# extract

A fast directory scanner that gives you and your AI agent a clean, readable tree with the context that actually matters: size, line count, last modified, file type, and more.

## Example

```bash
📁 my-project/                                    files      size      modified
├── 📁 src/                                        8 files   41.2 KB   2h ago
│   ├── 📄 index.ts [M]                              94L      2.1 KB   2h ago
│   ├── 📄 config.ts [A]                             61L      1.4 KB   1d ago
│   ├── 📁 utils/                                  3 files   12.6 KB   3d ago
│   │   ├── 📄 parser.ts [?]                        218L      5.3 KB   3d ago
│   │   ├── 📄 helpers.ts                           179L      4.1 KB   3d ago
│   │   └── 📄 types.ts [M]                         134L      3.2 KB   5d ago
│   └── 📁 core/                                   3 files   25.1 KB   2h ago
│       ├── 📄 extract.ts [M]                       502L     11.4 KB   2h ago
│       ├── 📄 walker.ts                            389L      8.9 KB   4h ago
│       └── 📄 formatter.ts                         201L      4.8 KB   2d ago
├── 📄 package.json                                  38L      1.2 KB   1d ago
├── 📄 tsconfig.json                                 22L      0.6 KB   7d ago
├── 🔗 dist -> ./build/out                                      link   2d ago
└── 📄 README.md                                     87L      5.3 KB   1h ago

┌────────────────────────────────────────────────────────────────────────────┐
│   12 files     3 dirs     1 link    +4 hidden    1,925 lines    48.3 KB    │
├──────────────────────┬─────────────────────────────────────────────────────┤
│ largest              |    extract.ts                            11.4 KB    │
│ newest               |    index.ts                              2h ago     │
│ types                |    ts: 8              json: 2            md: 1      │
├──────────────────────┴─────────────────────────────────────────────────────┤
│ ⚡ scanned in 11ms                2026-02-21                      2:32pm    │
└────────────────────────────────────────────────────────────────────────────┘
```

**NOTE:** Don't worry, you can change the output styling and data amount to your liking in `config.yaml` to save tokens.

## Installation

> **Requires Python 3.8+** — install it from [python.org](https://www.python.org/downloads/) if needed.

### Linux / macOS

```bash
curl -sSL https://raw.githubusercontent.com/omnious0o0/extract/main/.extract/install.sh | bash
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/omnious0o0/extract/main/.extract/install.ps1 | iex
```

This automatically:
- Downloads the `extract` script
- Creates an `extract.bat` launcher so you can run `extract` directly from CMD or PowerShell
- Adds the install directory to your user `PATH`

To install into a custom directory:
```powershell
.\install.ps1 -InstallDir C:\tools\extract
```

## Usage

```bash
extract <path/to/directory> # or . for current directory
```

### Filtering
```bash
--ignore -f path, path, ... -t type, type, ... -e extension, extension, ... -n name, name, ...
# path: ignore specific files/folders by path
# type: ignore specific types (file, dir, link)
# extension: ignore specific extensions (e.g. .git)
# name: ignore specific names (e.g. node_modules)

# Replace --ignore with --only to show only the specified files/folders
```

**Show everything** (including anything blocked by config):
```bash
--full
```

## config.yaml

Stop retyping flags every time. Setting up `config.yaml` is highly recommended to tune `extract` to your exact workflow needs. It supports deep customization for styling, ignored paths, and rendering details:

```yaml
paths:
  - path
types: []
extensions: []
names: []

# File visibility controls
ignore_hidden: true
ignore_empty: false
```

**Other settings:**
```yaml
styling: low          # full | low (recommended) | minimal (removes colors, NOT RECOMMENDED)
emojis: false         # true | false (recommended)
scan_data: full       # full (recommended) | medium | low | minimal

scan_timeout: 60      # seconds
auto_update: true
auto_copy: false      # copy to clipboard after scan
```

> By default, hidden and common files/folders are ignored. Edit `config.yaml` to change this.

## Support

If you liked extract, please consider starring the repo and dropping me a follow for more stuff like this :)
It takes less than a minute and helps a lot ❤️

If you want to show extra love, consider *[buying me a coffee](https://buymeacoffee.com/specter0o0)*! ☕

**RECOMMENDED:** Check out [commands-wrapper](https://github.com/omnious0o0/commands-wrapper) you and your agent will love it!

[![Buy Me a Coffee](https://imgs.search.brave.com/FolmlC7tneei1JY_QhD9teOLwsU3rivglA3z2wWgJL8/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly93aG9w/LmNvbS9ibG9nL2Nv/bnRlbnQvaW1hZ2Vz/L3NpemUvdzIwMDAv/MjAyNC8wNi9XaGF0/LWlzLUJ1eS1NZS1h/LUNvZmZlZS53ZWJw)](https://buymeacoffee.com/specter0o0)

## License

[MIT](LICENSE)