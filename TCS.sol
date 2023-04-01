//SPDX-License-Identifier: MIT
pragma solidity ^0.8;
pragma abicoder v2;

// import "./TCT.sol";
// Import Vault interface, error messages, and library for decoding join/exit data.
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-stable/StablePoolUserData.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v2-interfaces/contracts/vault/IAsset.sol";
import "@balancer-labs/v2-interfaces/contracts/standalone-utils/IBalancerQueries.sol";



// // Import ERC20Helpers for `_asIAsset`
import "@balancer-labs/v2-solidity-utils/contracts/helpers/ERC20Helpers.sol";

contract TCSFactory {

    IVault private constant vault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);//vault: 0xBA12222222228d8Ba445958a75a0704d566BF2C8
    IBalancerQueries private query = IBalancerQueries(0xE39B5e3B6D74016b2F6A9673D7d7493B6DF549d5);
    mapping(address => uint256) public totalDepositByUser;
    
    struct queryResult{
        uint256 bptOut; 
        uint256[] amountsIn;
    }

    uint256 public bptTokens;
    uint256[] public amountsTokenIn;

//create an array similar to that of the balancer get pool tokens.... then use that to map the deposits.
    //function to get user to send BCT NCT MCO2 to contract.
    
    //function to deposit to Balancer pool and receive BPT to contract.
    //address recipient removed from params
    function _addTokenLiquidityToBalancerPool(bytes32 poolId, address sender, uint256[] memory amountsIn,uint256[] memory maxAmountsIn, uint256 tokenIndex, uint256 minBptAmountOut) external {
        // require(amountsIn[tokenIndex] > 0, "Amount must be greater than 0");
        (IERC20[] memory tokens, , ) = vault.getPoolTokens(poolId);
        // Use BalancerErrors to validate input
        //_require(amountsIn.length == tokens.length, Errors.INPUT_LENGTH_MISMATCH);
        //Encode the userData for a multi-token join
        bytes memory userData = abi.encode(StablePoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, minBptAmountOut);
        IVault.JoinPoolRequest memory requests = IVault.JoinPoolRequest({
            assets: _asIAsset(tokens),
            maxAmountsIn: maxAmountsIn,
            userData: userData,
            fromInternalBalance: false
        });
        totalDepositByUser[msg.sender] += amountsIn[tokenIndex];
        tokens[tokenIndex + 1].transferFrom(sender, address(this), amountsIn[tokenIndex]);
        tokens[tokenIndex + 1].approve(0xBA12222222228d8Ba445958a75a0704d566BF2C8, amountsIn[tokenIndex]);
        // Call the Vault to join the pool
        
        vault.joinPool(poolId, address(this), address(this), requests);
    }

    //function to withdraw from Balancer Pool by burning TCT

    //get functions to get BP TVL
    //get function to get number of BPT with contract

    function _queryAddLiquidity(bytes32 poolId, address sender, uint256 tokenIndex, uint256[] calldata amountIn) public{
        (IERC20[] memory tokens, , ) = vault.getPoolTokens(poolId);
        
        bytes memory userData = abi.encode(StablePoolUserData.JoinKind.TOKEN_IN_FOR_EXACT_BPT_OUT);
        IVault.JoinPoolRequest memory requests = IVault.JoinPoolRequest({
            assets: _asIAsset(tokens),
            maxAmountsIn: amountIn,
            userData: userData,
            fromInternalBalance: false
        });

        (bptTokens, amountsTokenIn) = query.queryJoin(poolId, sender, address(this), requests);
        
    }

    
}

