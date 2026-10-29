#!/usr/bin/env bash

set +x
set -euo pipefail
umask 077

gh api repos/lwouis/alt-tab-website/dispatches -f event_type=update-website
