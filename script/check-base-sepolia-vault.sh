#!/usr/bin/env bash
set -euo pipefail
shopt -s nocasematch

RPC_URL="${BASE_SEPOLIA_RPC_URL:-https://sepolia.base.org}"
FACTORY="0x524A95082dAD59fd8bf18FA27F89E3f55202eEcf"
VAULT="0x45004e3a5992606201B53Cd0FBab7f9439B4476C"
OWNER="0xE8405844a45C209895afE2e49be6aA2C6C6202a6"
USDC="0x036CbD53842c5426634e7929541eC2318f3dCF7e"
VERSION_ID="0x7cd4187df3151f8b6dba7f8b29a43eb0d551f30262c0c0885dd40f776328670f"
CONFIG_HASH="0xbdc507dcc83036b928e0a56ee2040435e270a56b6ad1543d1d767e528da4e7ff"
RUNTIME_HASH="0xc20bd075c8734260925eaf1f285e15f554734510cc81c3a3b45bcda05680bed2"

failures=0

first_field() {
  awk '{ print $1 }'
}

read_call() {
  cast call --rpc-url "$RPC_URL" "$@" | first_field
}

assert_equal() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    printf 'PASS  %s: %s\n' "$label" "$actual"
  else
    printf 'FAIL  %s: expected %s, got %s\n' "$label" "$expected" "$actual" >&2
    failures=$((failures + 1))
  fi
}

assert_equal "factory registry" "true" "$(read_call "$FACTORY" 'isVault(address)(bool)' "$VAULT")"
assert_equal "vault owner" "$OWNER" "$(read_call "$VAULT" 'owner()(address)')"
assert_equal "vault asset" "$USDC" "$(read_call "$VAULT" 'asset()(address)')"
assert_equal "version id" "$VERSION_ID" "$(read_call "$VAULT" 'versionId()(bytes32)')"
assert_equal "vault state" "0" "$(read_call "$VAULT" 'vaultState()(uint8)')"
assert_equal "config hash" "$CONFIG_HASH" "$(read_call "$VAULT" 'currentConfigHash()(bytes32)')"
assert_equal "vault USDC" "20000000" "$(read_call "$USDC" 'balanceOf(address)(uint256)' "$VAULT")"
assert_equal "owner allowance" "0" "$(read_call "$USDC" 'allowance(address,address)(uint256)' "$OWNER" "$VAULT")"
assert_equal "runtime hash" "$RUNTIME_HASH" "$(cast codehash --rpc-url "$RPC_URL" "$VAULT")"

liveness_nonce="$(read_call "$VAULT" 'livenessNonce()(uint64)')"
if (( liveness_nonce >= 2 )); then
  printf 'PASS  liveness nonce: %s\n' "$liveness_nonce"
else
  printf 'FAIL  liveness nonce: expected at least 2, got %s\n' "$liveness_nonce" >&2
  failures=$((failures + 1))
fi

if (( failures > 0 )); then
  printf 'Base Sepolia vault monitor failed with %s mismatches.\n' "$failures" >&2
  exit 1
fi

printf 'Base Sepolia vault monitor passed.\n'
