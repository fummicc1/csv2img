#!/bin/bash

set -e
set -x

current_dir=`realpath $0`
cd `dirname $current_dir`/../

act -P macos-14=-self-hosted -l --container-architecture linux/amd64

export LOCAL=true

act -P macos-14=-self-hosted -W ./.github/workflows/core.yml --container-architecture linux/amd64
act -P macos-14=-self-hosted -W ./.github/workflows/command.yml --container-architecture linux/amd64
act -P macos-14=-self-hosted -W ./.github/workflows/builder.yml --container-architecture linux/amd64