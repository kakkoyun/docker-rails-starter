#!/bin/sh
set -e

# Run the container startup scripts
. /service/etc/profile

launch root "$@"
