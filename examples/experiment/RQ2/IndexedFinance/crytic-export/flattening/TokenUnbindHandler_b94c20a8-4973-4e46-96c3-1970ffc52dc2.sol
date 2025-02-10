pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
interface TokenUnbindHandler {
  /**
   * @dev Receive `amount` of `token` from the pool.
   */
  function handleUnbindToken(address token, uint256 amount) external;
}
