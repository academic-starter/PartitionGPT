import os
import json
from typing import Tuple
from .dependency import ProgramDependency
from .compile import Compilation, ContractWrapper
from .slicer import Slicer
from .taint_tracking import TaintTrack
from src.extractor.nonascii_remove import remove_non_ascii_for_a_file

PartitionMode = None


def taint_analysis(file_path, target_contract_name, sensitive_vars, solc_version, solc_remaps) -> Tuple[ProgramDependency, TaintTrack]:
    instance = Compilation(contract_file=file_path,
                           solc_remaps=solc_remaps, solc_version=solc_version)

    wrapper = ContractWrapper(
        target_contract_name=target_contract_name, compilation=instance)
    pdg = ProgramDependency(contract=wrapper)
    pdg.generate_dependencies()

    tainter = TaintTrack(pdg, sensitive_var_names=sensitive_vars)
    tainter.compute()
    return pdg, tainter


def split(file_path, target_contract_name, sensitive_var_name, solc_version, solc_remaps=['@openzeppelin=node_modules/@openzeppelin'], mode="simple", outputdir="./"):
    global PartitionMode
    PartitionMode = mode
    # instance = Compilation(contract_file=file_path,
    #                        solc_remaps=solc_remaps, solc_version=solc_version)

    # wrapper = ContractWrapper(
    #     target_contract_name=target_contract_name, compilation=instance)

    # pdg = ProgramDependency(contract=wrapper)
    # pdg.generate_dependencies()

    # tainter = TaintTrack(pdg, sensitive_var_names=[sensitive_var_name])
    # tainter.compute()
    remove_non_ascii_for_a_file(file_path)
    pdg, tainter = taint_analysis(
        file_path, target_contract_name, sensitive_var_name.split(","), solc_version, solc_remaps)

    slicer = Slicer(tainter=tainter, pdg=pdg)
    pragma, cs_privates, cs_publics, other_libraries_or_external_contracts, all_cfi_policies, all_temporal_lock_policies, all_partition_result = slicer.compute_all_function_slices()

    json.dump(all_partition_result, open(os.path.join(
        outputdir, target_contract_name+".partition.json"), "w"), indent=4)

    private_contract_name = os.path.join(
        outputdir, target_contract_name + ".private.sol")
    public_contract_name = os.path.join(
        outputdir, target_contract_name + ".public.sol")
    open(private_contract_name, "w").write(
        "\n".join([pragma] + [cs.generate_code() for cs in cs_privates] + other_libraries_or_external_contracts))
    open(public_contract_name, "w").write(
        "\n".join([pragma] + [cs.generate_code() for cs in cs_publics] + other_libraries_or_external_contracts))

    cmd = "js-beautify {0} -o {0}"
    os.system(cmd.format(private_contract_name))
    os.system(cmd.format(public_contract_name))

    cfi_policy_json = os.path.join(
        outputdir, target_contract_name + ".cfi.json")
    json.dump(all_cfi_policies, open(cfi_policy_json, "w"), indent=4)

    temporal_policy_json = os.path.join(
        outputdir, target_contract_name + ".lock.json")
    json.dump(all_temporal_lock_policies, open(
        temporal_policy_json, "w"), indent=4)
