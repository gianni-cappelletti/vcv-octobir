# OctobIR - VCV Rack

VCV Library packaging repository for **OctobIR**, an impulse response loader with
static and dynamic blending options.

The plugin's source lives in the
[October Production Co. monorepo](https://github.com/gianni-cappelletti/October-Production-Co),
pinned here as the `opc` git submodule. This repository is a thin wrapper whose
only purpose is to present a standard Rack plugin (`plugin.json` + `Makefile`) at
its root, which is what the VCV Library build farm requires. No plugin source is
duplicated here.

## Layout

```
Makefile        Rack plugin build; sources point into opc/, includes plugin.mk
plugin.json     Library manifest (canonical; must be a real file at the root)
opc/            submodule: the full monorepo (source of truth)
res/            materialised from opc/ at build time (git-ignored)
```

## Building locally

Requires a Rack SDK (or a full Rack source tree). Point `RACK_DIR` at it:

```sh
export RACK_DIR=/path/to/Rack-SDK
make dep     # initialises the opc submodule and its WDL dependency
make dist    # builds and packages dist/OPC-OctobIR-<version>-<arch>.vcvplugin
```

`make dep` provisions only what the VCV build needs (the monorepo and its WDL
sub-submodule); it does not pull the monorepo's JUCE or NeuralAmpModelerCore
submodules.

## Releasing a new version

1. Point the submodule at the monorepo commit you want to ship:
   ```sh
   git -C opc fetch
   git -C opc checkout <monorepo-release-commit>
   git add opc
   ```
2. Bump `version` in `plugin.json` to match.
3. Commit and tag, then push.
4. Comment on the plugin's VCV Library submission thread with the new version and
   commit hash so the farm rebuilds it.

## Continuous integration

`.github/workflows/build.yml` mirrors the VCV Library build farm
([rack-plugin-toolchain](https://github.com/VCVRack/rack-plugin-toolchain)):

- **win-x64, lin-x64** are cross-compiled inside the toolchain Docker image
  (`ghcr.io/qno/rack-plugin-toolchain-win-linux`) via `make plugin-build-<platform>`,
  exactly as the farm does.
- **mac-x64, mac-arm64** are built natively on a macOS runner (Apple's SDK cannot
  be redistributed in a public image), using `CROSS_COMPILE` to select the arch.
- A `provisioning-check` job builds `lin-x64` natively with no submodules checked
  out, verifying that `make dep` self-provisions `opc` and WDL.
- On a `v*` tag, all four `.vcvplugin` artifacts are attached to a GitHub Release.

## License

GPL-3.0-or-later. See `LICENSES/`.
