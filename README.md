# extract

A fast directory scanner that gives you and your AI agent a clean, readable tree with context that matters: size, line count, last modified, file type, and git markers.

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

## Installation

> Requires Python 3.8+.

### Linux / macOS

```bash
curl -fsSL -o install.sh https://raw.githubusercontent.com/omnious0o0/extract/main/.extract/install.sh
bash install.sh
rm -f install.sh
```

### Windows (PowerShell)

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/omnious0o0/extract/main/.extract/install.ps1" -OutFile "install.ps1"
powershell -ExecutionPolicy Bypass -File .\install.ps1
Remove-Item .\install.ps1
```

The installers download release artifacts (`extract` + `extract.sha256`) and verify the SHA-256 checksum before install.

## Usage

```bash
extract [path]
```

### Common options

```bash
--version
--check-updates
--self-update
--enable-auto-update
--disable-auto-update
--auto-update-status
--no-auto-update
--install-bat [DIR]          # Windows launcher helper
--config <path/to/config.yaml>
--styling-mode full|low|minimal
--scan-emojis true|false
--scan-data full|medium|low|minimal
--scan-structure dynamic|static
--full
```

### Filtering

```bash
-f, --paths path1,path2,...          # match relative paths
-t, --types file,dir,link            # match node kinds
-e, --extensions .py,.ts,...         # match file extensions
-n, --names node_modules,.git,...    # match basenames
```

- Ignore mode uses config ignore rules plus CLI selectors.
- `--ignore` is optional when rules are present.
- `--only` shows only matching entries and bypasses ignore + hidden filtering.
- `--full` bypasses all ignore and visibility filters.

## config.yaml

```yaml
paths:
  - .git
types: []
extensions: []
names: []

ignore_hidden: true
ignore_empty: false

styling: low
scan_emojis: false
scan_data: full
scan_structure: dynamic

scan_timeout: 60
auto_update: false
auto_copy: false
```

Notes:
- If no config file is found, common noisy folders/files are ignored by default.
- Config discovery order: explicit `--config`, target directory, executable directory, global config directory.

## Security notes

- Self-update validates checksum metadata before replacing the installed script.
- For controlled environments, pin updates with `EXTRACT_SOURCE_SHA256`.

## Support

Open an issue or pull request for bugs, regressions, or feature requests.

## License

[MIT](LICENSE)
