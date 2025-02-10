contract BasicMathBad {
    function add_uncheck(uint256 a, uint256 b) public pure returns(uint256) {
        unchecked {
            return a * b;
        }
    }
}