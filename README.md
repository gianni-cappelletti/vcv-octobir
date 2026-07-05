# OctobIR - VCV Rack

VCV Library packaging repository for **OctobIR**, an impulse response loader for
[VCV Rack](https://vcvrack.com).

The plugin source lives in the
[October-Production-Co monorepo](https://github.com/gianni-cappelletti/October-Production-Co),
pinned here as the `opc` submodule. This repository provides a standard Rack
plugin (`plugin.json` + `Makefile`) at its root - the layout the VCV Library build
farm builds from - with sources pointing into the submodule. No source is
duplicated.

## Repositories

| Repository | Role |
|---|---|
| [October-Production-Co](https://github.com/gianni-cappelletti/October-Production-Co) | Source of truth (monorepo): OctobIR VCV + JUCE, `octobir-core`, WDL. Pinned here as `opc`. |
| vcv-octobir (this repo) | VCV Library packaging wrapper; the `sourceUrl` the Library builds. |

## Layout

```
Makefile      Rack plugin build; sources point into opc/; includes $(RACK_DIR)/plugin.mk
plugin.json   Library manifest (real file at root)
LICENSES/     SPDX license texts (REUSE-compliant)
.github/      CI mirroring the VCV Library build farm
opc/          submodule: the monorepo (source of truth)
res/          materialised from opc/ at build time (git-ignored)
```

## Build

`Makefile` includes `$(RACK_DIR)/plugin.mk`, providing the standard `clean`,
`cleandep`, `dep`, and `dist` targets. Wrapper-specific behaviour:

- `make dep` initialises the `opc` submodule and its WDL and pffft sub-submodules
  only, not the monorepo's JUCE or NeuralAmpModelerCore submodules.
- `res/` is copied from the submodule at `dist` time. `plugin.mk` packages
  `DISTRIBUTABLES` with path-preserving flags (`rsync -rR` / `cp --parents`) and
  requires a top-level `res/`.
- `plugin.json` is a real file at the root. `plugin.mk` reads `slug`/`version`
  from it on every invocation, including `make clean`, which runs before any
  submodule is initialised.
- `-fsigned-char` is set. WDL static-asserts that `char` is signed, which is
  false by default on `mac-arm64`.

Local build:

```sh
export RACK_DIR=/path/to/Rack-SDK
make dep
make dist    # -> dist/OPC-OctobIR-<version>-<arch>.vcvplugin
```

`make dep` must precede `make dist`.

## Release

1. Pin the submodule to the monorepo release tag: `git -C opc checkout vX.Y.Z && git add opc`
2. Set `version` in `plugin.json` to `X.Y.Z`.
3. Commit, tag `vX.Y.Z`, and push.
4. Comment on the plugin's VCV Library thread with the version and commit hash.

## CI

`.github/workflows/build.yml`:

- `win-x64`, `lin-x64`: built in the `ghcr.io/qno/rack-plugin-toolchain-win-linux`
  image via `make plugin-build-<platform>`.
- `mac-x64`, `mac-arm64`: built on a macOS runner; `CROSS_COMPILE` selects the arch.
- `provisioning-check`: native `lin-x64` build with no submodules, exercising
  `make dep` self-provisioning.
- `publish`: on a `v*` tag, attaches the four `.vcvplugin` artifacts to a GitHub
  Release.

## License

GPL-3.0-or-later; see `LICENSES/`. Bundled third-party code (WDL, dr_wav) is
carried through the `opc` submodule under its own compatible license.
