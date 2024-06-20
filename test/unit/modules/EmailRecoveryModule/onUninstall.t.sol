// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/console2.sol";
import { ModuleKitHelpers } from "modulekit/ModuleKit.sol";
import { MODULE_TYPE_EXECUTOR } from "modulekit/external/ERC7579.sol";
import { SentinelListLib } from "sentinellist/SentinelList.sol";
import { SentinelListHelper } from "sentinellist/SentinelListHelper.sol";
import { UnitBase } from "../../UnitBase.t.sol";

contract EmailRecoveryModule_onUninstall_Test is UnitBase {
    using ModuleKitHelpers for *;
    using SentinelListHelper for address[];

    function setUp() public override {
        super.setUp();
    }

    // TODO: Assess
    function test_OnUninstall_RevertWhen_InvalidValidatorsLength() public {
        vm.prank(accountAddress);
        instance.uninstallModule(MODULE_TYPE_EXECUTOR, recoveryModuleAddress, "");
        vm.stopPrank();
    }

    function test_OnUninstall_Succeeds() public {
        vm.prank(accountAddress);
        instance.uninstallModule(MODULE_TYPE_EXECUTOR, recoveryModuleAddress, "");
        vm.stopPrank();

        bytes4 allowedSelector =
            emailRecoveryModule.exposed_allowedSelectors(validatorAddress, accountAddress);
        address allowedValidator =
            emailRecoveryModule.exposed_selectorToValidator(functionSelector, accountAddress);
        assertEq(allowedSelector, bytes4(0));
        assertEq(allowedValidator, address(0));

        address[] memory allowedValidators =
            emailRecoveryModule.getAllowedValidators(accountAddress);
        bytes4[] memory allowedSelectors = emailRecoveryModule.getAllowedSelectors(accountAddress);
        assertEq(allowedValidators.length, 0);
        assertEq(allowedSelectors.length, 0);
    }

    function test_OnUninstall_SucceedsWhenNoValidatorsConfigured() public {
        address[] memory allowedValidators =
            emailRecoveryModule.getAllowedValidators(accountAddress);
        address prevValidator = allowedValidators.findPrevious(validatorAddress);

        vm.startPrank(accountAddress);
        emailRecoveryModule.disallowValidatorRecovery(
            validatorAddress, prevValidator, "", functionSelector
        );
        vm.stopPrank();

        allowedValidators = emailRecoveryModule.getAllowedValidators(accountAddress);
        bytes4[] memory allowedSelectors = emailRecoveryModule.getAllowedSelectors(accountAddress);
        assertEq(allowedValidators.length, 0);
        assertEq(allowedSelectors.length, 0);

        vm.prank(accountAddress);
        instance.uninstallModule(MODULE_TYPE_EXECUTOR, recoveryModuleAddress, "");
        vm.stopPrank();

        allowedValidators = emailRecoveryModule.getAllowedValidators(accountAddress);
        allowedSelectors = emailRecoveryModule.getAllowedSelectors(accountAddress);
        assertEq(allowedValidators.length, 0);
        assertEq(allowedSelectors.length, 0);
    }
}
