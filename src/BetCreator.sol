// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./vaults/RiskVault.sol";
import "./vaults/HedgeVault.sol";

contract BetCreator {
    address public immutable controller;
    IERC20 public immutable asset;
    
    uint256 private nextBetId;
    
    mapping(uint256 => BetVaults) public betVaults;
    
    struct BetVaults {
        address riskVault;
        address hedgeVault;
    }
    
    event BetVaultsCreated(
        uint256 indexed betId,
        address indexed riskVault,
        address indexed hedgeVault
    );
    
    constructor(address controller_, address asset_) {
        require(controller_ != address(0), "Invalid controller address");
        require(asset_ != address(0), "Invalid asset address");
        controller = controller_;
        asset = IERC20(asset_);
        nextBetId = 1;
    }
    
    function createBetVaults() 
        external 
        returns (
            uint256 betId,
            address riskVault,
            address hedgeVault
        ) 
    {
        betId = nextBetId++;
        
        // Deploy Hedge vault first
        HedgeVault hedge = new HedgeVault(
            asset,
            controller,
            betId
        );
        
        hedgeVault = address(hedge);
        
        // Deploy Risk vault with Hedge vault address
        RiskVault risk = new RiskVault(
            asset,
            controller,
            hedgeVault,
            betId
        );
        
        riskVault = address(risk);
        
        // Set sister vault in Hedge vault
        hedge.setSisterVault(riskVault);
        
        // Store vault addresses
        betVaults[betId] = BetVaults({
            riskVault: riskVault,
            hedgeVault: hedgeVault
        });
        
        emit BetVaultsCreated(betId, riskVault, hedgeVault);
        
        return (betId, riskVault, hedgeVault);
    }
    
    function getVaults(uint256 betId) 
        external 
        view 
        returns (
            address riskVault,
            address hedgeVault
        ) 
    {
        BetVaults memory vaults = betVaults[betId];
        require(vaults.riskVault != address(0), "Bet does not exist");
        return (vaults.riskVault, vaults.hedgeVault);
    }
}