# omni-extract

omni-extract is a tool to extract directory tree alongside important information for your agent like: size, last modified, type, etc.

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

## installation

**One-liner:**
```bash
curl -sSL https://raw.githubusercontent.com/omnious0o0/omni-extract/main/.omni-extract/install.sh | bash
```

## usage

It's very easy to use, just run:
```bash
extract <path/to/directory> # or . for current directory
```

**Optionally, yet highly recommended, add:** 
```bash
--ignore -f path, path, ... -t type, type, ... -e extension, extension, ... -n name, name, ...
# path: ignore specific files/folders by path
# type: ignore specific types (file, dir, link)
# extension: ignore specific extensions (EG. .git)
# name: ignore specific names (EG. node_modules)
```

## config.yaml
**You can always set them in `config.yaml` to make it persistent:**
> Yaml structure:
```yaml
paths: {
    - path
    ...
}
types: {...}
extensions: {...}
names: {...}
```

**Note:** On default hidden & common files and folders are ignored, you can edit the `config.yaml` file to change this, along with many other options.

## Support

If you liked omni-extract, please consider starring the repo, and dropping me a follow for more stuff like this :)  
It takes less than a minute and will help a lot ❤️  

If you want to show extra love, consider *[buying me a coffee](https://buymeacoffee.com/specter0o0)*! ☕

[![alt text](https://imgs.search.brave.com/FolmlC7tneei1JY_QhD9teOLwsU3rivglA3z2wWgJL8/rs:fit:860:0:0:0/g:ce/aHR0cHM6Ly93aG9w/LmNvbS9ibG9nL2Nv/bnRlbnQvaW1hZ2Vz/L3NpemUvdzIwMDAv/MjAyNC8wNi9XaGF0/LWlzLUJ1eS1NZS1h/LUNvZmZlZS53ZWJw)](https://buymeacoffee.com/specter0o0)

## License

[MIT](LICENSE)