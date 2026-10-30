# Rosemary Portage overlay

Unofficial Gentoo packaging for [Rosemary](https://github.com/microlift/rosemary),
a compatibility layer for running macOS applications on Linux.

`app-emulation/rosemary-0.4.1` builds the upstream release from source. It uses
Gentoo's `cargo.eclass`, pins Git dependencies to the upstream `Cargo.lock`, and
builds offline after Portage fetches the sources. The bundled, patched mimalloc
is preserved. No Rust toolchain is downloaded by the ebuild itself.

## Install

Create `/etc/portage/repos.conf/rosemary.conf`:

```ini
[rosemary]
location = /var/db/repos/rosemary
sync-type = git
sync-uri = https://github.com/nunreasonable/rosemary-gentoo-overlay.git
auto-sync = yes
```

Accept the package's testing keyword in
`/etc/portage/package.accept_keywords/rosemary`:

```text
app-emulation/rosemary ~amd64
```

Then sync and install:

```sh
emaint sync -r rosemary
emerge --ask app-emulation/rosemary
```

The release requires Rust 1.99 or later and SDL 3.4 or later. Portage may ask for
additional keywords for these dependencies on a stable system. `dev-lang/rust-bin`
is supported; compiling Rust from source is not necessary. Use a desktop profile
or configure the graphical dependencies' USE flags for your system.

| USE flag | Default | Runtime dependency |
| --- | --- | --- |
| `opengl` | on | GLVND and GLU for OpenGL.framework |
| `vulkan` | on | Vulkan loader for Metal; a suitable GPU driver is also needed |
| `webkit` | on | WebKitGTK 6 for embedded macOS web views |

These flags control optional runtime dependencies, not Cargo features. Disabling
one leaves the corresponding applications without that backend. SDL3 and OpenAL
are always installed. The package installs the `rosemary` command, desktop entry,
and upstream documentation. On first use, Rosemary downloads its macOS userland
into a per-user prefix; this is separate from installation by Portage.

## Container validation

With rootless Podman installed:

```sh
bash .ci/podman-test.sh
```

The script uses the official `gentoo/stage3` image and Gentoo binhost for build
and runtime dependencies. It runs pkgcheck, then builds and installs Rosemary
from source in a second container with **no network**. It checks the installed
version, help output, shared-library resolution, desktop entry and runtime
library loading. Limits are 2 CPUs, 8 GiB RAM and 1 GiB additional swap.
Only inside the test containers, Portage's nested IPC, PID and network sandboxes
are disabled because rootless Podman already provides those namespaces. The
filesystem sandbox remains enabled, and the build container has no network.

Containers and the intermediate local image are retained for inspection; their
names are printed. Remove those specific resources with `podman rm` and
`podman rmi` when finished. No host GPU, display, home directory or macOS prefix
is mounted. The read-only overlay mount uses Podman's SELinux `:Z` relabeling.

Only `~amd64` is keyworded. Loading runtime libraries does not validate graphical
applications or GPU rendering. The upstream test suite is restricted in the
ebuild because it requires Mach-O fixtures, a display and a GPU.

### Validation on 2026-10-30

- Official Gentoo stage3, Portage tree snapshot dated 2026-10-29, desktop profile.
- Rust 1.99.0, GCC 16.2.1, SDL 3.4.18 and WebKitGTK 2.54.0 (slot 6).
- `pkgcheck scan --exit error`: no findings.
- All 319 registry archives matched the SHA-256 checksums in upstream's lockfile.
- Offline preparation preserved all package versions; only the 21 Git packages
  were redirected to local copies of the same commits.
- Clean release compilation and Portage installation with default USE flags
  passed in a rootless container with `--network=none` (5m 31s compilation).
- Installed version, help, dynamic linking, desktop entry and six runtime library
  loading checks passed; the test container exited with status 0.

Known non-fatal output: `cargo.eclass` recommends a crate tarball for this many
dependencies. Individual upstream archives are used here so the overlay does not
depend on a separately hosted vendor bundle. Upstream Microlift has an unused
method warning. Portage's attempt to set an extended attribute on the executable
is unsupported by this container storage backend; installation still succeeds.
