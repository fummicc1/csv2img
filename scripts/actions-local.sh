#!/bin/bash

set -e

current_dir=`realpath $0`
cd `dirname $current_dir`/../

act -P macos-14=-self-hosted

# Because xcode-setup does not work on local machine, make local flag true to skip xcode-setup
export LOCAL=true

act -P macos-14=-self-hosted -W ./.github/workflows/core.yml
act -P macos-14=-self-hosted -W ./.github/workflows/command.yml
act -P macos-14=-self-hosted -W ./.github/workflows/builder.yml
