#!/usr/bin/env bash
set -euo pipefail

readonly rpc_url="${BASE_MAINNET_RPC_URL:-https://mainnet.base.org}"

BASE_MAINNET_RPC_URL="${rpc_url}" forge test \
  --match-contract BaseMainnetUSDCForkTest \
  -vv
