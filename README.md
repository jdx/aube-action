# aube-action

GitHub Action that installs [aube](https://github.com/endevco/aube) and
adds it to `PATH`. Optionally installs Node.js inline via
[mise](https://mise.jdx.dev) so the same step covers both the package
manager and the runtime.

## Usage

```yaml
- uses: endevco/aube-action@v1
- run: aube install
```

Pin a specific aube version and run `aube install` in one go:

```yaml
- uses: endevco/aube-action@v1
  with:
    version: 1.5.1
    run-install: true
```

Install Node.js too — explicit version:

```yaml
- uses: endevco/aube-action@v1
  with:
    node-version: "22"
    run-install: true
```

Or let mise pick up the version from the project's `mise.toml`,
`.tool-versions`, `.nvmrc`, `.node-version`, or
`package.json` `devEngines.runtime`:

```yaml
- uses: endevco/aube-action@v1
  with:
    node-version: auto
    run-install: true
```

## Inputs

| Input               | Default               | Description |
|---------------------|-----------------------|-------------|
| `version`           | `latest`              | aube version. `latest`, a semver (`1.5.1`), or a tag (`v1.5.1`). |
| `node-version`      | _(empty)_             | `auto` to resolve from project files; otherwise forwarded to `mise install-into node@<value>`. |
| `run-install`       | `false`               | Run `aube install` after the binary is on `PATH`. |
| `install-args`      | _(empty)_             | Extra arguments appended to `aube install`. |
| `working-directory` | workspace root        | Directory used for `aube install` and for `node-version: auto` discovery. |
| `token`             | `${{ github.token }}` | Used for the release download to avoid unauthenticated rate limits. |

## Outputs

| Output           | Description |
|------------------|-------------|
| `version`        | Resolved aube version (without the `v` prefix). |
| `bin-path`       | Directory containing `aube`, `aubr`, `aubx`. |
| `node-version`   | Resolved Node.js version, or empty if node was not installed. |
| `node-bin-path`  | Directory containing the `node` binary, or empty. |

## Platform support

| Runner           | aube | Node via `node-version` |
|------------------|------|-------------------------|
| `ubuntu-latest`  | yes  | yes                     |
| `ubuntu-*-arm`   | yes  | yes                     |
| `macos-latest`   | yes  | yes                     |
| `macos-13` (x64) | no — use `cargo install aube --locked` | n/a |
| `windows-latest` | yes  | yes                     |

## How it works

- Downloads the prebuilt aube archive from
  `https://github.com/endevco/aube/releases` matching the runner's OS and
  arch, extracts to `$RUNNER_TEMP`, and prepends that directory to
  `$GITHUB_PATH`.
- For Node.js, downloads mise inline (POSIX shell installer on
  Linux/macOS; standalone `.exe` from `jdx/mise` releases on Windows)
  and runs `mise install-into node@<ver> <dir>` to drop a self-contained
  Node tree into `$RUNNER_TEMP/aube-action-node/<ver>`. `mise install` is
  never run, so a project's `mise.toml` is consulted for discovery only
  — unrelated tools listed there are not installed.

## Discussion

aube uses GitHub Discussions for bug reports and questions:
<https://github.com/endevco/aube/discussions>.
