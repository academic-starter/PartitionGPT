from blockscan import Blockscan
import os
import json

ETH = 1
ETH_API_KEY = "E5DUFDNUDQXT4BEA72S511FM7IPE3TA36S"

BSC = 56
BSC_API_KEY = "A4YZESUAIA4IGXSBK8D4NYQMUBMWTVAXN9"

ARBITRUM = 42161
ARBITRUM_API_KEY = "ASP9TI59228EG6RR8PVPGRXJKVG5AY9Y4B"


def save_src(result):
    print(len(result), " contracts")
    src = result[0]["SourceCode"].strip()
    contractName = result[0]["ContractName"]
    if src.startswith("{{") and src.endswith("}}"):
        src = src[1:-1]
        src = json.loads(src)

    if isinstance(src, str):
        sol_file = os.path.join(os.path.dirname(__file__), contractName+".sol")
        open(sol_file, "w").write(src)
    else:
        print(" is composed by multiple files")
        print(type(src))
        if isinstance(src, dict):
            print("Keys: {0}".format(src.keys()))
            sources = src["sources"]
            for sub_file in sources:
                code = sources[sub_file]["content"]
                sol_file = os.path.join(os.path.dirname(
                    __file__), contractName, sub_file)
                if not os.path.exists(os.path.dirname(sol_file)):
                    os.makedirs(os.path.dirname(sol_file))
                open(sol_file, "w").write(code)
        else:
            exit(0)


# client = Blockscan(ETH, ETH_API_KEY, is_async=False)

# result = client.contracts.get_contract_source_code(
#     contract_address="0xacd43e627e64355f1861cec6d3a6688b31a6f952")


client = Blockscan(BSC, BSC_API_KEY, is_async=False)

result = client.contracts.get_contract_source_code(
    contract_address="0x93c175439726797dcee24d08e4ac9164e88e7aee")

save_src(result)


# client = Blockscan(ARBITRUM, ARBITRUM_API_KEY, is_async=False)

# result = client.contracts.get_contract_source_code(
#     contract_address="0x3e30fdae04c08fc20fa2fe0cf55c95d99a9c2d8f")

# save_src(result)
