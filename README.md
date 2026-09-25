# aube-action

GitHub Action that installs [aube](https://github.com/endevco/aube) and
adds it to `PATH`. Optionally installs Node.js inline via
[mise](https://mise.jdx.dev) so the same step covers both the package
manager and the runtime.

## Usage

```yaml
- uses: jdx/aube-action@v1
- run: aube ci
```

Pin a specific aube version and run `aube ci` in one go:

```yaml
- uses: jdx/aube-action@v1
  with:
    version: 1.5.1
    run-install: true
```

Install Node.js too — explicit version:

```yaml
- uses: jdx/aube-action@v1
  with:
    node-version: "22"
    run-install: true
```

Or let mise pick up the version from the project's `mise.toml`,
`.tool-versions`, `.nvmrc`, `.node-version`, or
`package.json` `devEngines.runtime`:

```yaml
- uses: jdx/aube-action@v1
  with:
    node-version: auto
    run-install: true
```

Cache `node_modules` between runs:

```yaml
- uses: jdx/aube-action@v1
  with:
    node-version: "24"
    run-install: true
    cache: true
```

With `cache: true`, the action restores `node_modules` from
[`actions/cache`](https://github.com/actions/cache) and installs with
`aube install --frozen-lockfile`, which keeps a restored tree that already
matches the lockfile. It doesn't use `aube ci`, because that deletes
`node_modules` first. After an install that missed the cache, the action saves
the result immediately, before later steps can write into `node_modules`.

The cache key includes the runner OS and architecture, the Node.js and aube
versions, the checkout path, and every lockfile aube reads (`aube-lock.yaml`,
`pnpm-lock.yaml`, `bun.lock`, `yarn.lock`, `npm-shrinkwrap.json`,
`package-lock.json`), every `package.json`, `aube-workspace.yaml`,
`pnpm-workspace.yaml`, and `.npmrc` under `working-directory` (outside
`node_modules`), and the `install-args` and `cache-path` inputs. The Node.js
version matters because dependency builds can compile native addons for one
Node.js ABI. The checkout path matters because some links in `node_modules`
store absolute paths. There is no partial-match fallback: a restored tree is
either an exact match or not used. For a workspace, list each member's
`node_modules` in `cache-path`:

```yaml
- uses: jdx/aube-action@v1
  with:
    node-version: "24"
    run-install: true
    cache: true
    cache-path: |
      node_modules
      packages/*/node_modules
```

## Inputs

| Input               | Default               | Description |
|---------------------|-----------------------|-------------|
| `version`           | `latest`              | aube version. `latest`, a semver (`1.5.1`), or a tag (`v1.5.1`). |
| `node-version`      | _(empty)_             | `auto` to resolve from project files; otherwise forwarded to `mise install-into node@<value>`. |
| `run-install`       | `false`               | Run `aube ci` after the binary is on `PATH` (`aube install --frozen-lockfile` with `cache: true`). |
| `install-args`      | _(empty)_             | Extra arguments appended to the install command. |
| `cache`             | `false`               | Restore and save `node_modules` with `actions/cache`. Requires `run-install: true`. |
| `cache-path`        | `node_modules`        | Newline-separated directories to cache, relative to `working-directory`. Globs work. |
| `working-directory` | workspace root        | Directory used for `aube ci` and for `node-version: auto` discovery. |
| `token`             | `${{ github.token }}` | Used for the release download to avoid unauthenticated rate limits. |

## Outputs

| Output           | Description |
|------------------|-------------|
| `version`        | Resolved aube version (without the `v` prefix). |
| `bin-path`       | Directory containing `aube`, `aubr`, `aubx`. |
| `node-version`   | Resolved Node.js version, or empty if node was not installed. |
| `node-bin-path`  | Directory containing the `node` binary, or empty. |
| `cache-hit`      | `true` when `node_modules` was restored from an exact cache match. |

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

## Bugs and questions

Report aube bugs and ask questions in GitHub Discussions:
<https://github.com/endevco/aube/discussions>.
