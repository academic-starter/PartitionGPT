merge_prompt_template="""
Suppose you are an expert developers for Solidity smart contracts. There are two smart contract versions: A, B having different implementations of function {func_name}. Your task is to merge B code with A's. 

A's code:
```
{contract_a}
```

B's code:
```
{contract_b}
```

Please STRICTLY follow the steps one by one.
1. MUST rename ``{func_name}`` of B's contract {contract_name} as ``{func_name}_new``. THEN merge the modified B's code into A within a same contract. Repetition of functions are not allowed.
2. All the resulting code MUST satisfy the grammar of Solidity programming language.

You MUST output all the result in plain text format, and avoid unnecessary text description.
"""

import os
import glob
import json
import re 
import pandas as pd 
import numpy as np 
import openai
from tqdm import tqdm
from src.vector_db import config
openai.api_key = config.OPENAI_API_KEY

def get_llm_result(prompt):
    # few-shot learning
    chat_completion = openai.ChatCompletion.create(
        messages=[
            {
                "role": "user",
                "content": prompt,
            }
        ],
        model="gpt-4o",
    )

    response = chat_completion.choices[0].message
    refusal = response.refusal
    content = response.content
    # print(content)
    return content

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


# work_dir = "./advanced-gpt4o_mini"

for work_dir in ["./advanced-qwen_25_32b", "./advanced-llama3.1_latest", "./advanced-gemma2_27b" ]:
    partition_files = glob.glob(os.path.join(work_dir, "*.partition.json"))

    for partition_file in partition_files:
        all_partitions = json.load(open(partition_file))
        contract_name = os.path.basename(partition_file).split(".")[0].strip()
        func_count = len(all_partitions)
        partition_count = np.sum([len(func_partitions["partitions"]) for func_partitions in all_partitions])
        non_partition_func_count = len(list(filter(lambda func_partitions: len(func_partitions["partitions"])==0, all_partitions)))
        Top_ks = dict()
        print(contract_name)
        for func_partitions in tqdm(all_partitions):
            results = []
            func_name = func_partitions["target_func_name"]
            partitions = func_partitions["partitions"]
            original_code = func_partitions["original_code"]
            all_extern_deps_code = func_partitions["all_extern_deps_code"]
            for index in partitions:
                partition = partitions[index]
                partition_code = partition["output_code"]
                merge_prompt = merge_prompt_template.format(contract_name=contract_name, func_name=func_name, contract_a=original_code, contract_b=partition_code)
                
                # print(partition_code)
                
                # Regex to match Solidity function definitions with optional modifiers and their bodies
                # Regex to match Solidity function definitions with all considerations
                # function_pattern = (
                #     r"function\s+\w+\s*"              # Match 'function' keyword and function name
                #     r"\([^)]*\)\s*"                    # Match parameters in parentheses, allowing newlines
                #     r"(?:public|internal|external|private)?\s*"  # Match optional visibility
                #     r"(?:\s*\w+\([^)]*\)|\s*\w+)*\s*"        # Match zero or more modifiers, including with parameters
                #     r"(?:returns\s*\([^)]*\))?\s*"     # Match optional returns declaration
                #     r"\{(?:[^{}]*|(?R))*\}"            # Match function body using recursive matching for nested braces
                # )

                # # Extracting all function definitions
                # functions = re.findall(function_pattern, partition_code, re.DOTALL)
                functions = extract_functions(partition_code)
                # Printing extracted functions
                target_func_name_pattern = re.compile(rf"\s+{func_name}\s*", re.DOTALL)
                priv_func_name_pattern = re.compile(rf"\s+\w+\_priv\s*", re.DOTALL)
                target_func_code = "" 
                new_sub_func_codes = []
                for idx, function in enumerate(functions, 1):
                    # print(f"Function {idx}:\n{function}\n")
                    if function.find(f" {func_name}(")!=-1:
                        target_func_code = function.replace(f" {func_name}(", f" {func_name}_new(")
                    elif function.find("_priv(")!=-1:
                        new_sub_func_codes.append(function.strip())
                    elif function.find("_callback(")!=-1:
                        new_sub_func_codes.append(function.strip())
                
                # print(target_func_code)
                # print(priv_func_codes)
                index = original_code.rfind("}")
                merge_code = original_code[:index] + "\n\t"+ target_func_code + "\n\t" + "\n\t".join(new_sub_func_codes) + "\n}"
                # print(merge_code)
                # exit(0)
        #         result = get_llm_result(merge_prompt)
        #         code = result.replace("```solidity", "").replace("```", "")
                partition["merged_code"] = merge_code
        
        json.dump(all_partitions, open(partition_file, "w"), indent=4)      
