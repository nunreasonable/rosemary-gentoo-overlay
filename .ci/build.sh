#!/bin/bash
set -euo pipefail

# The caller starts this container with --network=none.
[[ -f /etc/gentoo-release ]]
emerge --usepkg=n --oneshot =app-emulation/rosemary-0.4.1
rosemary --version | grep -Fx 'rosemary 0.4.1'
rosemary --help
ldd /usr/bin/rosemary > /tmp/rosemary-ldd.txt
cat /tmp/rosemary-ldd.txt
! grep -q 'not found' /tmp/rosemary-ldd.txt
test -f /usr/share/applications/rosemary.desktop
python - <<'PY'
import ctypes
for library in (
    'libSDL3.so.0', 'libopenal.so.1', 'libvulkan.so.1',
    'libGL.so.1', 'libGLU.so.1', 'libwebkitgtk-6.0.so.4',
):
    ctypes.CDLL(library)
    print(f'Loaded {library}')
PY

FEATURES=test emerge --usepkg=n --oneshot =games-util/ginrose-0.3.1
for name in ginrose ginrose-studio; do
    "${name}" status
    ! ldd "/usr/bin/${name}" | grep -q 'not found'
done
test -f /usr/share/applications/me.daeese.apps.ginrose.player.desktop
test -f /usr/share/applications/me.daeese.apps.ginrose.studio.editor.desktop
