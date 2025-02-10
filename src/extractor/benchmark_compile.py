import os
import traceback
import json
from slither.core.declarations import SolidityFunction
from slither.core.declarations.function_contract import FunctionContract
from src.framework.compile import Compilation, ContractWrapper
from src.extractor.sourcecode_catcher import SourceCodeCatcher
from src.extractor.nonascii_remove import remove_non_ascii_for_a_file


def common_compile(contract_file, solc_remaps, solc_version, target_contract):
    instance = Compilation(contract_file=contract_file,
                           solc_remaps=solc_remaps, solc_version=solc_version)

    wrapper = ContractWrapper(
        target_contract_name=target_contract, compilation=instance)

    print("state variables:")
    for state_var in wrapper.get_all_state_variables():
        print(state_var.name, state_var.type)
    return wrapper


def get_partitions(original_wrapper: ContractWrapper, partition_wrapper: ContractWrapper):
    partitions = []

    def containt_priv_function(function: FunctionContract):
        if function.name.endswith("_priv"):
            return True
        result = False
        for internal_call in function.internal_calls:
            if not isinstance(internal_call, SolidityFunction):
                result = containt_priv_function(internal_call)
                if result:
                    break
        return result

    for function in partition_wrapper.get_functions():
        if function.visibility in ["public", "external"]:
            for internal_call in function.all_internal_calls():
                if internal_call.name.endswith("_priv"):
                    print(function.name, internal_call.name)
                    partitions.append(dict(target_contract_name=original_wrapper.contract.name, target_func_name=function.name, original=SourceCodeCatcher.get_and_gen_wrapper_contract_for_function(original_wrapper.get_functions_from_name(
                        function.name)[0], original_wrapper)[0], partition=SourceCodeCatcher.get_and_gen_wrapper_contract_for_function(function, partition_wrapper)[0]))
                    break
    return partitions


def partition_compile(benchmark_dir, contract_dir, contract_name):
    contract_file = os.path.join(benchmark_dir,
                                 contract_dir, "intermediate_partition", contract_name+".sol")
    remove_non_ascii_for_a_file(contract_file)
    solc_remaps = "@openzeppelin=examples/benchmark/curated/raw/node_modules/@openzeppelin"
    solc_version = "0.8.25"
    target_contract = contract_name
    return common_compile(contract_file, solc_remaps, solc_version, target_contract)


def original_compile(benchmark_dir, contract_dir,  contract_name):
    contract_file = os.path.join(benchmark_dir,
                                 contract_dir, "original", contract_name+".sol")
    remove_non_ascii_for_a_file(contract_file)
    solc_remaps = "@openzeppelin=examples/benchmark/curated/raw/node_modules/@openzeppelin"
    solc_version = "0.8.25"
    target_contract = contract_name
    return common_compile(contract_file, solc_remaps, solc_version, target_contract)


def extract_partitions(benchmark_dir, contract_dir, contract_name):
    print("Extracting partitions for " + contract_name)
    original_wrapper = original_compile(
        benchmark_dir=benchmark_dir, contract_dir=contract_dir, contract_name=contract_name)
    partition_wrapper = partition_compile(
        benchmark_dir=benchmark_dir, contract_dir=contract_dir, contract_name=contract_name)
    partitions = get_partitions(
        original_wrapper=original_wrapper, partition_wrapper=partition_wrapper)
    # print(json.dumps(partitions, indent=4))
    public_external_func_count = len(list(filter(lambda func: func.visibility in ["public", "external"], original_wrapper.contract.functions)))
    return partitions, public_external_func_count


benchmark_dir = "./examples/benchmark/curated/manual_partitions"

benchmark_contracts = [
    "AuctionInstance",
    "ConfidentialAuction",
    "EncryptedERC20",
    "NFTExample",
    "Battleship",
    "ConfidentialERC20",
    "EncryptedFunds",
    "Suffragium",
    "BlindAuction",
    "ConfidentialIdentityRegistry",
    "GovernorZama",
    "CipherBomb",
    "DarkPool",
    "IdentityRegistry",
    "VickreyAuction",
    "Comp",
    "Leaderboard",
    "TokenizedAssets"
]


if __name__ == "__main__":
    # compile()

    all_partitions = dict()
    cnts = []
    for item in benchmark_contracts:
        partitions, public_external_func_count = extract_partitions(benchmark_dir, item, item)
        all_partitions[item] = partitions
        # print(item, public_external_func_count)
        cnts.append([item, public_external_func_count, len(partitions)])

    print("Contract\t ||public|external functions||")
    for cnt_item in cnts:
        print(cnt_item[0], cnt_item[1], cnt_item[2])
    json.dump(all_partitions, open(
        "./partition_benchmark.json", "w"), indent=4)
    # try:
    #     original_compile(benchmark_dir=benchmark_dir,
    #                      contract_dir=item, contract_name=item)
    #     print("original {} compilation success!".format(item))
    # except:
    #     traceback.print_exc()
    #     print("original {} compilation failed!".format(item))
    # try:
    #     partition_compile(benchmark_dir=benchmark_dir,
    #                       contract_dir=item, contract_name=item)
    #     print("partitioned {} compilation success!".format(item))
    # except:
    #     traceback.print_exc()
    #     print("partitioned {} compilation failed!".format(item))
