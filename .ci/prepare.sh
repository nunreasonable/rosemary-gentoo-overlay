#!/bin/bash
set -euo pipefail

# Run only inside the disposable Gentoo test container.
[[ -f /etc/gentoo-release && -d /overlay ]]
emerge-webrsync
eselect profile set default/linux/amd64/23.0/desktop
mkdir -p /etc/portage/{repos.conf,package.accept_keywords,package.use}
cat > /etc/portage/repos.conf/gentoo.conf <<'EOF'
[DEFAULT]
main-repo = gentoo
[gentoo]
location = /var/db/repos/gentoo
EOF
cat > /etc/portage/repos.conf/rosemary.conf <<'EOF'
[rosemary]
location = /var/db/repos/rosemary
auto-sync = no
EOF
cp -a /overlay /var/db/repos/rosemary
cat > /etc/portage/package.accept_keywords/rosemary <<'EOF'
app-emulation/rosemary ~amd64
games-util/ginrose ~amd64
dev-lang/rust-bin ~amd64
EOF
cat > /etc/portage/package.use/ginrose <<'EOF'
games-util/ginrose player studio
EOF
cat > /etc/portage/package.use/container-desktop <<'EOF'
*/* X wayland opengl
EOF
# Match desktop variants available from the official binhost.
cat > /etc/portage/package.use/binhost <<'EOF'
net-libs/webkit-gtk:6 keyring
media-video/pipewire gstreamer
x11-misc/xdg-utils gnome
EOF
cat >> /etc/portage/make.conf <<'EOF'
MAKEOPTS="-j2"
# Rootless Podman already isolates these namespaces. Portage cannot create
# nested ones without extra capabilities; the build container has no network.
FEATURES="${FEATURES} -ipc-sandbox -network-sandbox -pid-sandbox"
EOF
emerge --getbinpkg --oneshot dev-lang/rust-bin dev-util/pkgcheck
emerge --getbinpkg --oneshot --onlydeps =app-emulation/rosemary-0.4.1
emerge --getbinpkg --oneshot --onlydeps =games-util/ginrose-0.3.3
ebuild /var/db/repos/rosemary/app-emulation/rosemary/rosemary-0.4.1.ebuild manifest
ebuild /var/db/repos/rosemary/games-util/ginrose/ginrose-0.3.3.ebuild manifest
pkgcheck scan --exit error --repo /var/db/repos/rosemary
