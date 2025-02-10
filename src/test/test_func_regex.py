import re

# Sample Solidity code
solidity_code = """
contract ExampleContract {
    address public owner;

    function auctionEnd(
        uint64 bid
    ) public 
      onlyAfterEnd(beneficiary)
      onlyAuthorized
      returns (bool success)
    {
        require(!tokenTransferred);
        tokenTransferred = true;
        tokenContract.transfer(beneficiary, bid);
        return true;
    }

    function auctionEnd_priv(
        uint64 bid, 
        bool flag
    ) internal 
      onlyAuthorized(owner) 
    {
        require(flag);
        tokenContract.transfer(beneficiary, bid);
    }

    function example(
        uint256 param
    ) public 
      view 
      onlyOwner 
      returns (uint256 result) 
    {
        return param;
    }
}
"""

# Regex to match Solidity function definitions with all considerations
function_pattern = (
    r"function\s+\w+\s*"              # Match 'function' keyword and function name
     r"\([^)]*\)\s*"                    # Match parameters in parentheses, allowing newlines
    r"(?:public|internal|external|private)?\s*"  # Match optional visibility
    r"(?:\s*\w+\([^)]*\)|\s*\w+)*\s*"        # Match zero or more modifiers, including with parameters
    r"(?:returns\s*\([^)]*\))?\s*"     # Match optional returns declaration
    r"{.*?}"                         # Match function body non-greedily
)

# Extracting all function definitions
functions = re.findall(function_pattern, solidity_code, re.DOTALL)

# Printing extracted functions
for idx, function in enumerate(functions, 1):
    print(f"Function {idx}:\n{function}\n")