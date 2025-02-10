contract BasicMathGood {
    uint256 sum;
    function add(uint256 a, uint256 b) public returns(uint256) {
        sum = a + b;
        return a + b;
    }
}