#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 -m venv /workspace/watchweeks-tools/venv
/workspace/watchweeks-tools/venv/bin/python -m pip install --no-input 'pbxproj==4.3.3' 'openstep-parser==2.0.3' 'docopt==0.6.2'
env -u DOCKER_HOST -u DOCKER_CONTEXT -u DOCKER_TLS -u DOCKER_TLS_VERIFY -u DOCKER_CERT_PATH docker --host=unix:///var/run/docker.sock pull swift@sha256:0e4716bd34384d22963a63afbdbc93be3129dfd0753185aa1ded27755abdcae8
