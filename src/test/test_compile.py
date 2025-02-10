from src.framework.compile import Compilation, ContractWrapper


def compile():
    contract_file = "examples/benchmark/curated/manual_partitions/AuctionInstance/intermediate_partition/AuctionInstance.sol"
    solc_remaps = "@openzeppelin=examples/benchmark/curated/raw/node_modules/@openzeppelin"
    solc_version = "0.8.25"
    target_contract = "AuctionInstance"
    instance = Compilation(contract_file=contract_file,
                           solc_remaps=solc_remaps, solc_version=solc_version)

    wrapper = ContractWrapper(
        target_contract_name=target_contract, compilation=instance)

    print("state variables:")
    for state_var in wrapper.get_all_state_variables():
        print(state_var.name, state_var.type)

    print("functions:")
    for function in wrapper.get_functions():
        print(function.name, function.type)
    return wrapper


if __name__ == "__main__":
    compile()
