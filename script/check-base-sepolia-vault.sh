#!/usr/bin/env bash
set -euo pipefail
shopt -s nocasematch

RPC_URL="${BASE_SEPOLIA_RPC_URL:-https://sepolia.base.org}"
FACTORY="0x935e5101d7563429BC152889603D3A17f466f4e4"
VAULT="0x21ea6A01Dd4A7C9F87Bdc80773fbB765FF6fa371"
OWNER="0xE8405844a45C209895afE2e49be6aA2C6C6202a6"
USDC="0x036CbD53842c5426634e7929541eC2318f3dCF7e"
VERSION_ID="0x2307fc907cb859b0cb1ee608138ba346e301805703f489f8370477c357b73f56"
CONFIG_HASH="0xbdc507dcc83036b928e0a56ee2040435e270a56b6ad1543d1d767e528da4e7ff"
RUNTIME_HASH="0x100016fa0ed9ba6b03d57af1e255e6e1c475093a2dce36b8d407f9e0cc7b2aaa"

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
if (( liveness_nonce >= 3 )); then
  printf 'PASS  liveness nonce: %s\n' "$liveness_nonce"
else
  printf 'FAIL  liveness nonce: expected at least 3, got %s\n' "$liveness_nonce" >&2
  failures=$((failures + 1))
fi

if (( failures > 0 )); then
  printf 'Base Sepolia vault monitor failed with %s mismatches.\n' "$failures" >&2
  exit 1
fi

printf 'Base Sepolia vault monitor passed.\n'
