export const mutations = [
  {
    id: "I1",
    title: "permissionless claim rewrites owner liveness",
    file: "src/HeirloomVault.sol",
    test: "testI1_LastSeenChangesOnlyForOwnerAuthorizationOrRecovery",
    find: `    function requestClaim() external {
        if (vaultState != HeirloomTypes.VaultState.Active) revert InvalidState();`,
    replace: `    function requestClaim() external {
        lastSeen = uint64(block.timestamp);
        if (vaultState != HeirloomTypes.VaultState.Active) revert InvalidState();`,
  },
  {
    id: "I2",
    title: "permissionless config execution creates liveness",
    file: "src/HeirloomVault.sol",
    test: "testI2_PermissionlessConfigExecutionCannotCreateLiveness",
    find: `        delete pendingConfig;
        ++configNonce;
        _applyConfig(proposed);
        emit ConfigExecuted(pending.configHash, msg.sender, configNonce);`,
    replace: `        delete pendingConfig;
        ++configNonce;
        _applyConfig(proposed);
        lastSeen = uint64(block.timestamp);
        emit ConfigExecuted(pending.configHash, msg.sender, configNonce);`,
  },
  {
    id: "I3",
    title: "claim request omits the current configuration epoch",
    file: "src/HeirloomVault.sol",
    test: "testI3_ClaimRequestMovesNoAssetAndBindsCurrentEpochs",
    find: "            configNonce: configNonce",
    replace: "            configNonce: 0",
  },
  {
    id: "I4",
    title: "distribution accepts one stale request epoch",
    file: "src/HeirloomVault.sol",
    test: "testI4_DistributionRejectsAStaleRequestEpoch",
    find:
      "        if (request.livenessNonce != livenessNonce || request.configNonce != configNonce) {",
    replace:
      "        if (request.livenessNonce != livenessNonce && request.configNonce != configNonce) {",
  },
  {
    id: "I5",
    title: "executor redirects a primary payout to itself",
    file: "src/HeirloomVault.sol",
    test: "testI5_PermissionlessCallerCannotAimOrResizePayout",
    find: "            destination = _beneficiaries[beneficiaryIndex].primary;",
    replace: "            destination = msg.sender;",
  },
  {
    id: "I6",
    title: "primary phase remains valid at the fallback boundary",
    file: "src/HeirloomVault.sol",
    test: "testI6_ExactlyOneDestinationPhaseExistsAtFallbackBoundary",
    find:
      "        if (block.timestamp < fallbackAt) return HeirloomTypes.DestinationPhase.PrimaryOnly;",
    replace:
      "        if (block.timestamp <= fallbackAt) return HeirloomTypes.DestinationPhase.PrimaryOnly;",
  },
  {
    id: "I7",
    title: "fallback phase remains valid at the rollover boundary",
    file: "src/HeirloomVault.sol",
    test: "testI7_PrimaryAndFallbackAreImpossibleAtRolloverBoundary",
    find:
      "        if (block.timestamp < rolloverAt) return HeirloomTypes.DestinationPhase.FallbackOnly;",
    replace:
      "        if (block.timestamp <= rolloverAt) return HeirloomTypes.DestinationPhase.FallbackOnly;",
  },
  {
    id: "I8",
    title: "resolved entitlement may be executed again",
    file: "src/HeirloomVault.sol",
    test: "testI8_NonTerminalEntitlementResolvesExactlyOnce",
    find: `        if (_beneficiaryStatus[beneficiaryIndex] != HeirloomTypes.BeneficiaryStatus.Unresolved) {
            revert EntitlementAlreadyResolved();
        }`,
    replace: `        if (false) {
            revert EntitlementAlreadyResolved();
        }`,
  },
  {
    id: "I9",
    title: "terminal unlocks after only one non-terminal payout",
    file: "src/HeirloomVault.sol",
    test: "testI9_TerminalCannotUnlockBeforeEveryNonTerminalResolves",
    find: `        emit BeneficiaryPaid(beneficiaryIndex, destination, phase, amount, msg.sender);

        if (resolvedNonTerminalCount == _beneficiaries.length) _unlockTerminal();`,
    replace: `        emit BeneficiaryPaid(beneficiaryIndex, destination, phase, amount, msg.sender);

        _unlockTerminal();`,
  },
  {
    id: "I10",
    title: "configuration accepts a snapshot allocation below 100 percent",
    file: "src/HeirloomVault.sol",
    test: "testI10_EntitlementBpsMustConserveTheSnapshot",
    find: "        if (totalBps != TOTAL_BPS) revert InvalidConfiguration();",
    replace: "        if (totalBps > TOTAL_BPS) revert InvalidConfiguration();",
  },
  {
    id: "I11",
    title: "rollover incorrectly removes value from the terminal remainder",
    file: "src/HeirloomVault.sol",
    test: "testI11_RolloverRemainsInTerminalSnapshotExactlyOnce",
    find: `        ++resolvedNonTerminalCount;
        totalRolledOver += amount;

        emit EntitlementRolledOver(beneficiaryIndex, amount, msg.sender);`,
    replace: `        ++resolvedNonTerminalCount;
        totalRolledOver += amount;
        snapshotRemaining -= amount;

        emit EntitlementRolledOver(beneficiaryIndex, amount, msg.sender);`,
  },
  {
    id: "I12",
    title: "outgoing transfer accepts an excessive sender debit",
    file: "src/HeirloomVault.sol",
    test: "testI12_InexactTransferRevertsAllResolutionAccounting",
    find:
      "        if (afterBalance > beforeBalance || beforeBalance - afterBalance != amount) {",
    replace:
      "        if (afterBalance > beforeBalance || beforeBalance - afterBalance < amount) {",
  },
  {
    id: "I13",
    title: "successful payout leaves one unit in snapshot accounting",
    file: "src/HeirloomVault.sol",
    test: "testI13_SuccessfulPayoutTracksExactOutgoingDelta",
    find: "        snapshotRemaining -= amount;",
    replace: "        snapshotRemaining -= amount - 1;",
  },
  {
    id: "I14",
    title: "settled vault retains a nonzero snapshot remainder",
    file: "src/HeirloomVault.sol",
    test: "testI14_SettlementIsCompleteTerminalAndSingleUse",
    find: `        snapshotRemaining = 0;
        terminalPaid = true;`,
    replace: `        snapshotRemaining = 1;
        terminalPaid = true;`,
  },
  {
    id: "I15",
    title: "recovery executor chooses itself as the new owner",
    file: "src/HeirloomVault.sol",
    test: "testI15_RecoveryInstallsOnlyPrecommittedOwnerAndInvalidatesEpochs",
    find: "        owner = newOwner;",
    replace: "        owner = msg.sender;",
  },
  {
    id: "I16",
    title: "vault discards its factory-announced version identity",
    file: "src/HeirloomVault.sol",
    test: "testI16_FactoryAssetVersionAndRuntimeIdentityRemainVerifiable",
    find: "        versionId = vaultVersionId;",
    replace: "        versionId = bytes32(0);",
  },
];
