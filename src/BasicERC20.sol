import "solmate/tokens/ERC20.sol";

contract BasicERC20 is ERC20 {
  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_
  ) ERC20(name_, symbol_, decimals_) {}

  function mint(address to, uint256 amount) public {
    _mint(to, amount);
  }
}
