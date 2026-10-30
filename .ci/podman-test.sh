#!/bin/bash
set -euo pipefail

overlay=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
name="rosemary-portage-${UID}-$$"
image="localhost/${name}:prepared"
limits=(--memory=8g --memory-swap=9g --cpus=2 --pids-limit=2048)
printf 'Test containers: %s-prepare and %s-build\n' "$name" "$name"
podman run --name "${name}-prepare" "${limits[@]}" \
    -v "${overlay}:/overlay:ro,Z" docker.io/gentoo/stage3:latest \
    bash /overlay/.ci/prepare.sh
podman commit "${name}-prepare" "$image"
podman run --name "${name}-build" "${limits[@]}" \
    --network=none "$image" bash /var/db/repos/rosemary/.ci/build.sh
printf 'Tests passed. Containers and prepared image retained for inspection:\n%s\n' "$image"
