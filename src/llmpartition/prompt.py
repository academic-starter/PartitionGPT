transformation_example = """
Suppose you are an expert developers for Solidity smart contracts. There is a code transformation task of smart contract function where two program slices, i.e., the normal and privilege slices, have been given. In our slicing, slicing critera are a sequence of program statements that are labelled privileged. Your job is to transform the original contract function to a new variant encompassing these two program slices. The new function variant MUST be functionally equivalent with the original one.

Here is an example input.

```Normal
    function bid(uint64 value) external
    onlyBeforeEnd {
  	uint64 existingBid = bids[to];
        if (existingBid > 0) {}
        else {
            bidCounter++;
        }
    }

```

```Privilege
function bid(address to, uint64 value) external {

        uint64 existingBid = bids[to];
        if (existingBid > 0) {
            bool isHigher = existingBid < value;
            uint64 toTransfer = value - existingBid;
            uint64 amount = 0;
            if (isHigher) {
                amount = toTransfer;
            }
            bids[to] = existingBid + amount;
        } else {
            bids[to] = value;
           
        }

        uint64 currentBid = bids[to];
        if (highestBid == 0) {
            highestBid = currentBid;
        } else {
            bool isNewWinner = highestBid < currentBid;
            if (isNewWinner) {
                highestBid = currentBid;
            }
        }
    }
```

Please STRICTLY follow the below actions one by one: 
1. MUST identify all the privilege statements including conditional checks shared between the two program slices.
2. MUST base on the provided privilege and normal slice for creating new sub functions. Privileged slice-based sub function in the form of ``XXX_priv`` contains all the identified privileged statements. If priviledged functions need to yield return value, there must be a normal callback function in the form of ``XXX_callback`` to process the return value. If there are normal statements to execute after the priviledged sub function, there must be a be a normal callback function in the form of ``XXX_callback`` to process the normal statements.
3. NOTE if modifier statements contain privilege statements, then modifier statements MUST be included in the privileged sub function.
4. TRY to reduce those normal, i.e., non-privileged, statements in privileged sub functions as many as possible.
5. All the resulting code MUST satisfy the grammar of Solidity programming language.

Below is the expected output for this example.
```
    function bid(uint64 value) external
    onlyBeforeEnd {
        bool enable_equiv_block_1 = bid_priv(msg.sender, value);
        bid_callback(enable_equiv_block_1);
    }

    // this function will be called back from private contract
    function bid_callback(bool enable_equiv_block_1) external
    {
        if (enable_equiv_block_1) {
            bidCounter++;
        }
    }

    function bid_priv(address to, uint64 value) external {
        bool enable_equiv_block_1 = false;

        uint64 existingBid = bids[to];
        if (existingBid > 0) {
            bool isHigher = existingBid < value;
            uint64 toTransfer = value - existingBid;
            uint64 amount = 0;
            if (isHigher) {
                amount = toTransfer;
            }
            bids[to] = existingBid + amount;
        } else {
            bids[to] = value;
            enable_equiv_block_1 = true;
        }

        uint64 currentBid = bids[to];
        if (highestBid == 0) {
            highestBid = currentBid;
        } else {
            bool isNewWinner = highestBid < currentBid;
            if (isNewWinner) {
                highestBid = currentBid;
            }
        }

        return enable_equiv_block_1;
    }
"""

transformation_example2 = """
Suppose you are an expert developers for Solidity smart contracts. There is a code transformation task of smart contract function where two program slices, i.e., the normal and privilege slices, have been given. In our slicing, slicing critera are a sequence of program statements that are labelled privileged. Your job is to transform the original contract function to a new variant encompassing these two program slices. The new function variant MUST be functionally equivalent with the original one.

Here is an example input.

```Normal
function withdraw() public  
    onlyAfterEnd  {

}
```

```Privilege
function withdraw() public  
{
    uint64 bidValue = bids[msg.sender] ;
    if (bidValue < highestBid) {
        tokenContract.transfer(msg.sender, bidValue) ;
        bids[msg.sender] = 0 ;
    }
}
```

Please STRICTLY follow the below actions one by one: 
1. MUST identify all the privilege statements including conditional checks shared between the two program slices.
2. MUST base on the provided privilege and normal slice for creating new sub functions. Privileged slice-based sub function in the form of ``XXX_priv`` contains all the identified privileged statements. If priviledged functions need to yield return value, there must be a normal callback function in the form of ``XXX_callback`` to process the return value. If there are normal statements to execute after the priviledged sub function, there must be a be a normal callback function in the form of ``XXX_callback`` to process the normal statements.
3. NOTE if modifier statements contain privilege statements, then modifier statements MUST be included in the privileged sub function.
4. TRY to reduce those normal, i.e., non-privileged, statements in privileged sub functions as many as possible.
5. All the resulting code MUST satisfy the grammar of Solidity programming language.


Below is the expected output for this example.
```
   function withdraw() public onlyAfterEnd {
        withdraw_priv(msg.sender);
    }

    function withdraw_priv(address user) internal returns (bool) {
        uint64 bidValue = bids[user];
        if (bidValue < highestBid) {
            tokenContract.transfer(user, bidValue);
            bids[user] = 0;
        }
    }
"""

transformation_template = """
Suppose you are an expert developers for Solidity smart contracts. There is a code transformation task of smart contract function where two program slices, i.e., the normal and privilege slices, have been given. In our slicing, slicing critera are a sequence of program statements that are labelled privileged. Your job is to transform the original contract function to a new variant encompassing these two program slices. The new function variant MUST be functionally equivalent with the original one.

Here we list the original contract function code and its labeled privilege statements:
```Original contract function
{original_function_code}
```

```Privilege statements
{privilege_code}
```

Below are the resulting two program slices:
```Normal
{slice_normal}
```

```Privileged
{slice_priv}
```

Please STRICTLY follow the below actions one by one: 
1. MUST identify all the privilege statements including conditional checks shared between the two program slices.
2. MUST base on the provided privilege and normal slice for creating new sub functions. Privileged slice-based sub function in the form of ``XXX_priv`` contains all the identified privileged statements. If priviledged functions need to yield return value, there must be a normal callback function in the form of ``XXX_callback`` to process the return value. If there are normal statements to execute after the priviledged sub function, there must be a be a normal callback function in the form of ``XXX_callback`` to process the normal statements.
3. NOTE if modifier statements contain privilege statements, then modifier statements MUST be included in the privileged sub function.
4. TRY to reduce those normal, i.e., non-privileged, statements in privileged sub functions as many as possible.
5. All the resulting code MUST satisfy the grammar of Solidity programming language.

You MUST output all the result in plain text format.
Only output the transformed contract code, and avoid unnecessary text description.
"""

grammar_fix_template = """

You are an expert Solidity developer. Your task is to fix grammar errors in the given Solidity smart contract code while ensuring the logic and functionality remain intact. Follow these steps:

Syntactically  incorrect contract code as the input:
```
{input_contract}
```

Below is the error output from Solidity compiler.
```
{error_msg}
```

Your task is to correct syntax issues based on Solidity grammar rules and the above-mentioned compiler's error message.
All the resulting code MUST satisfy the grammar of Solidity programming language.
MUST Output only the Fixed Code: Provide the corrected Solidity code in proper format, and avoid unnecessary text description.
"""

instrumentation_template = """
Suppose you are an expert developers for Solidity smart contracts. There is a code partitioning task of smart contract function encompassing privilege and normal sub functions. Your job is to isolate these sub function into two indepedent functions that will eventually run in different smart contracts. Please instrument message passing events to orchestrate the execution of the two functions from different contracts. 

Here we list the function code:
```function
{transformed_function_code}
```

Please STRICTLY follow the below actions: 
1. MUST identify the invocation statements of privilege sub functions and normal sub functions.
2. MUST replace the function invocations with message passing events, where the arguments passed to a sub function is replaced with a newly created message passing event.
3. MUST make the normal sub function in so-called callback function and separate it from the body of entry function.
4. All the resulting code MUST satisfy the grammar of Solidity programming language.
6. Additionally, MUST produce the corresponding message passing policies, i.e., how the message events should be handled by which functions.

The instrumentation MUST follow the two rules.
1. MUST preserve the integrity of privilege and normal sub functions.
2. CANNOT include other new statements except message event emission.
3. DO NOT include constructor functions in these contract.
4. MUST include entry function in the normal contract.
5. CANNOT include any variable or statement involving the address of privilege contract or normal contract. 

You MUST output all the result in plain text format.
"""


format_template = """
You are both an expert Solidity formatter. Your task is to well format the given smart contract code. 
Follow these steps:

Original contract:
```
{original_contract}
```
All the resulting code MUST satisfy the grammar of Solidity programming language.
Only output the formatted contract code, and avoid unnecessary text description.
"""


verification_question_template = """
You are both an expert Solidity developer and a formal verification professional. Your task is to answer whether two smart contract versions are equivlant. 
Follow these steps:

Original contract:
```
{original_contract}
```

Its transformed version.
```
{transformed_contract}
```

Your task is to examine functional equivalence between these two smart contracts. 
Note that we only check the equivalence between same-name functions with visibility being public or external.
Given two same-name functions, we only check the equivalence of the causal change of state variables and function return values at the end of function execution when there is no reversion, and if there is reversion, we check if their reversion conditions.

Please only output Yes if they are equivalent. Otherwise, please output the reasons briefly.
"""


semantic_fix_question_template = """
You are both an expert Solidity developer and a formal verification professional. Your task is to fix semantically inequivalent contract version that was transformed from original contract.
 
Follow these steps:

Original contract:
```
{original_contract}
```

Its transformed version:
```
{transformed_contract}
```

Explanation for this inequivalence.
```
{explanation}
```

Your task is to make modification to the transformed contract version to ensure functional equivalence. Note that we only check the equivalence between same-name functions with visibility being public or external.

All the resulting code MUST satisfy the grammar of Solidity programming language.
Only output the transformed contract code, and avoid unnecessary text description.
"""


secure_fix_question_template = """
You are both an expert Solidity developer and a security experts. There is a code transformation task of smart contract function where two program slices, i.e., the normal and privilege slices, have been given. In our slicing, slicing critera are a sequence of program statements that are labelled privileged. Moreover, there is one bad partition result provided for reference.  Your job is to transform the original contract function to a new variant encompassing these two program slices. The new function variant MUST be functionally equivalent with the original one. 


Here we list the original contract function code and its labeled privilege statements: 
Original contract:
```
{original_contract}
```

Privilege code
```
{privilege_code}
```

Below are the resulting two program slices:
```Normal
{slice_normal}
```

```Privilege
{slice_priv}
```


One of bad partition results is given:
```
{transformed_contract}
```
due to 

```
{explanation}
```

Please STRICTLY follow the below actions: 
1. MUST identify all the identical privilege statements including identical conditional checks shared between the two program slices.
2. MUST remove all the identical privilege statements from the normal program slice.
3. MUST connect the privilege slice and the curated normal program slice for creating a new function variant, where each program slice is a sub function. Privilege slice sub function could have return values in order to forward control flow context for equivalent code blocks while normal slice sub function could have return values in order to propagate output. Privilege sub function MUST be executed before normal sub function.
4. All the resulting code MUST satisfy the grammar of Solidity programming language.

The transformation MUST follow the two rules.
1. MUST include all privilege statements in privilege part of the function variant.
2. CANNOT include privilege statements in normal part of the function variant.
3. TRY to include non-privileged statements in normal part of the function variant as many as possible.

You MUST output all the result in plain text format.
Only output the transformed contract code, and avoid unnecessary text description.

All the resulting code MUST satisfy the grammar of Solidity programming language.
Only output the transformed contract code, and avoid unnecessary text description.
"""
