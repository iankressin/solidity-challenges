import {Test} from "forge-std/Test.sol";
import {ETHPool} from "../src/ETHPool.sol";

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract DepositTest is Test {
    ETHPool public pool;

    function setUp() public {
        pool = new ETHPool();
    }
}
