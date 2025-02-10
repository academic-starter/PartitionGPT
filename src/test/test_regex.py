import re

# Sample Solidity code
solidity_code = """
contract ExampleContract {
    address public owner;

    function auctionEnd(
        uint64 bid
    ) public 
      onlyAfterEnd(beneficiary) 
      nonReentrant
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
      someOtherModifier 
    {
        require(flag);
        tokenContract.transfer(beneficiary, bid);
    }

    function example(
        uint256 param
    ) public 
      view 
      onlyOwner 
      anotherModifier 
      returns (uint256 result) 
    {
        if (true){
            data
        }else{
            data
        }
        return param;
    }
}
"""

# Function to match function headers and their bodies
def extract_functions(solidity_code):
    # Regex to match function definitions with modifiers, visibility, and returns
    function_pattern = (
        r"function\s+\w+\s*"              # Match 'function' keyword and function name
        r"\([^)]*\)\s*"                    # Match parameters in parentheses, allowing newlines
        r"(?:public|internal|external|private)?\s*"  # Match optional visibility
        r"(?:\s*\w+\([^)]*\)|\s*\w+)*\s*"        # Match zero or more modifiers, including with parameters
        r"(?:returns\s*\([^)]*\))?\s*"     # Match optional returns declaration
        r"\{"                              # Match opening brace of function body
    )

    # Find potential function headers
    matches = re.finditer(function_pattern, solidity_code, re.DOTALL)

    functions = []
    for match in matches:
        start = match.start()  # Start index of the match
        open_braces = 1        # Track opening braces
        end = match.end()      # Start looking after the header match

        # Parse the body of the function
        while open_braces > 0 and end < len(solidity_code):
            if solidity_code[end] == "{":
                open_braces += 1
            elif solidity_code[end] == "}":
                open_braces -= 1
            end += 1

        # Extract the full function code
        functions.append(solidity_code[start:end].strip())

    return functions

# Extract functions
functions = extract_functions(solidity_code)

# Print the results
for idx, func in enumerate(functions, 1):
    print(f"Function {idx}:\n{func}\n")