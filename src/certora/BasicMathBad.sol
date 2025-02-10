contract BasicMathBad {
    uint256 sum;
    function add_uncheck(uint256 a, uint256 b) public  {
        unchecked {
            sum = a * b;
            //return a * b;
        }
    }
}