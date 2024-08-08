// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IEmailRecoverySubjectHandler } from "../interfaces/IEmailRecoverySubjectHandler.sol";
import { StringUtils } from "../libraries/StringUtils.sol";

/**
 * Handler contract that defines subject templates and how to validate them
 * This is the default subject handler that will work with any validator.
 */
contract EmailRecoverySubjectHandler is IEmailRecoverySubjectHandler {
    error InvalidTemplateIndex(uint256 templateIdx, uint256 expectedTemplateIdx);
    error InvalidSubjectParams(uint256 paramsLength, uint256 expectedParamsLength);
    error InvalidAccount();
    error InvalidRecoveryModule(address recoveryModule);

    /**
     * @notice Returns a hard-coded two-dimensional array of strings representing the subject
     * templates for an acceptance by a new guardian.
     * @return string[][] A two-dimensional array of strings, where each inner array represents a
     * set of fixed strings and matchers for a subject template.
     */
    function acceptanceSubjectTemplates() public pure returns (string[][] memory) {
        string[][] memory templates = new string[][](1);
        templates[0] = new string[](5);
        templates[0][0] = "Accept";
        templates[0][1] = "guardian";
        templates[0][2] = "request";
        templates[0][3] = "for";
        templates[0][4] = "{ethAddr}";
        return templates;
    }

    /**
     * @notice Returns a hard-coded two-dimensional array of strings representing the subject
     * templates for email recovery.
     * @return string[][] A two-dimensional array of strings, where each inner array represents a
     * set of fixed strings and matchers for a subject template.
     */
    function recoverySubjectTemplates() public pure returns (string[][] memory) {
        string[][] memory templates = new string[][](1);
        templates[0] = new string[](11);
        templates[0][0] = "Recover";
        templates[0][1] = "account";
        templates[0][2] = "{ethAddr}";
        templates[0][3] = "via";
        templates[0][4] = "recovery";
        templates[0][5] = "module";
        templates[0][6] = "{ethAddr}";
        templates[0][7] = "using";
        templates[0][8] = "recovery";
        templates[0][9] = "hash";
        templates[0][10] = "{string}";
        return templates;
    }

    /**
     * @notice Extracts the account address to be recovered from the subject parameters of an
     * acceptance email.
     * @param subjectParams The subject parameters of the acceptance email.
     */
    function extractRecoveredAccountFromAcceptanceSubject(
        bytes[] calldata subjectParams,
        uint256 /* templateIdx */
    )
        public
        pure
        returns (address)
    {
        return abi.decode(subjectParams[0], (address));
    }

    /**
     * @notice Extracts the account address to be recovered from the subject parameters of a
     * recovery email.
     * @param subjectParams The subject parameters of the recovery email.
     */
    function extractRecoveredAccountFromRecoverySubject(
        bytes[] calldata subjectParams,
        uint256 /* templateIdx */
    )
        public
        pure
        returns (address)
    {
        return abi.decode(subjectParams[0], (address));
    }

    /**
     * @notice Validates the subject params for an acceptance email
     * @param templateIdx The index of the template used for acceptance
     * @param subjectParams The subject parameters of the recovery email.
     * @return accountInEmail The account address in the acceptance email
     */
    function validateAcceptanceSubject(
        uint256 templateIdx,
        bytes[] calldata subjectParams
    )
        external
        pure
        returns (address)
    {
        if (templateIdx != 0) {
            revert InvalidTemplateIndex(templateIdx, 0);
        }
        if (subjectParams.length != 1) {
            revert InvalidSubjectParams(subjectParams.length, 1);
        }

        // The GuardianStatus check in acceptGuardian implicitly
        // validates the account, so no need to re-validate here
        address accountInEmail = abi.decode(subjectParams[0], (address));

        return accountInEmail;
    }

    /**
     * @notice Validates the subject params for an acceptance email
     * @param templateIdx The index of the template used for the recovery request
     * @param subjectParams The subject parameters of the recovery email
     * @param expectedRecoveryModule The recovery module address. Used to help with validation
     * @return accountInEmail The account address in the acceptance email
     */
    function validateRecoverySubject(
        uint256 templateIdx,
        bytes[] calldata subjectParams,
        address expectedRecoveryModule
    )
        public
        view
        returns (address)
    {
        if (templateIdx != 0) {
            revert InvalidTemplateIndex(templateIdx, 0);
        }
        if (subjectParams.length != 3) {
            revert InvalidSubjectParams(subjectParams.length, 3);
        }

        address accountInEmail = abi.decode(subjectParams[0], (address));
        address recoveryModuleInEmail = abi.decode(subjectParams[1], (address));
        string memory recoveryDataHashInEmail = abi.decode(subjectParams[2], (string));
        // hexToBytes32 validates the recoveryDataHash is not zero bytes and has the correct length
        StringUtils.hexToBytes32(recoveryDataHashInEmail);

        if (accountInEmail == address(0)) {
            revert InvalidAccount();
        }

        // Even though someone could use a malicious contract as the expectedRecoveryModule
        // argument, it does not matter in this case as this is only used as part of the recovery
        // flow in the recovery module. Passing the recovery module in the constructor here would
        // result in a circular dependency
        if (recoveryModuleInEmail == address(0) || recoveryModuleInEmail != expectedRecoveryModule)
        {
            revert InvalidRecoveryModule(recoveryModuleInEmail);
        }

        return accountInEmail;
    }

    /**
     * @notice parses the recovery data hash from the subject params. The data hash is
     * verified against later when recovery is executed
     * @dev recoveryDataHash = abi.encode(validator, recoveryFunctionCalldata)
     * @param templateIdx The index of the template used for the recovery request
     * @param subjectParams The subject parameters of the recovery email
     * @return recoveryDataHash The keccak256 hash of the recovery data
     */
    function parseRecoveryDataHash(
        uint256 templateIdx,
        bytes[] calldata subjectParams
    )
        external
        pure
        returns (bytes32)
    {
        if (templateIdx != 0) {
            revert InvalidTemplateIndex(templateIdx, 0);
        }

        string memory recoveryDataHashInEmail = abi.decode(subjectParams[2], (string));
        return StringUtils.hexToBytes32(recoveryDataHashInEmail);
    }
}
