// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/BetCreator.sol";
import "../src/vaults/RiskVault.sol";
import "../src/vaults/HedgeVault.sol";
import "./mocks/MockToken.sol";

contract BetCreatorTest is Test {
    BetCreator public betCreator;
    MockToken public token;
    address public controller;
    address public user;
    
    event BetVaultsCreated(
        uint256 indexed betId,
        address indexed riskVault,
        address indexed hedgeVault
    );

    function setUp() public {
        controller = makeAddr("controller");
        user = makeAddr("user");
        
        token = new MockToken();
        betCreator = new BetCreator(controller, address(token));
        
        vm.label(address(betCreator), "BetCreator");
        vm.label(address(token), "Token");
        vm.label(controller, "Controller");
        vm.label(user, "User");
    }

    function test_Constructor() public view {
        assertEq(betCreator.controller(), controller);
        assertEq(address(betCreator.asset()), address(token));
    }

    function test_ConstructorZeroAddressReverts() public {
        vm.expectRevert("Invalid controller address");
        new BetCreator(address(0), address(token));

        vm.expectRevert("Invalid asset address");
        new BetCreator(controller, address(0));
    }

    function test_CreateFirstBet() public {
        // Create first bet
        (uint256 betId, address riskVault, address hedgeVault) = betCreator.createBetVaults();
        
        // Check initial conditions
        assertEq(betId, 1, "First bet should have ID 1");
        assertTrue(riskVault != address(0), "Risk vault should be deployed");
        assertTrue(hedgeVault != address(0), "Hedge vault should be deployed");
        assertTrue(riskVault != hedgeVault, "Vaults should be different");
        
        // Verify vault configurations
        HedgeVault hedge = HedgeVault(hedgeVault);
        RiskVault risk = RiskVault(riskVault);
        
        // Check hedge vault setup
        assertEq(hedge.controller(), controller, "Hedge vault controller wrong");
        assertEq(hedge.betId(), betId, "Hedge vault betId wrong");
        assertEq(address(hedge.asset()), address(token), "Hedge vault asset wrong");
        assertEq(hedge.owner(), address(betCreator), "Hedge vault owner wrong");
        assertEq(hedge.sisterVault(), riskVault, "Hedge vault sister wrong");
        
        // Check risk vault setup
        assertEq(risk.controller(), controller, "Risk vault controller wrong");
        assertEq(risk.betId(), betId, "Risk vault betId wrong");
        assertEq(address(risk.asset()), address(token), "Risk vault asset wrong");
        assertEq(risk.sisterVault(), hedgeVault, "Risk vault sister wrong");
    }

    function test_CreateMultipleBets() public {
        // Create first bet
        (uint256 betId1, address risk1, address hedge1) = betCreator.createBetVaults();
        assertEq(betId1, 1, "First bet ID wrong");
        
        // Create second bet
        (uint256 betId2, address risk2, address hedge2) = betCreator.createBetVaults();
        assertEq(betId2, 2, "Second bet ID wrong");
        
        // Verify vaults are different
        assertTrue(risk1 != risk2, "Risk vaults should be different");
        assertTrue(hedge1 != hedge2, "Hedge vaults should be different");
        
        // Check storage for both bets
        (address storedRisk1, address storedHedge1) = betCreator.getVaults(betId1);
        (address storedRisk2, address storedHedge2) = betCreator.getVaults(betId2);
        
        assertEq(storedRisk1, risk1, "Stored risk1 wrong");
        assertEq(storedHedge1, hedge1, "Stored hedge1 wrong");
        assertEq(storedRisk2, risk2, "Stored risk2 wrong");
        assertEq(storedHedge2, hedge2, "Stored hedge2 wrong");
    }

    function test_GetVaultsNonExistent() public {
        vm.expectRevert("Bet does not exist");
        betCreator.getVaults(1);
    }
}