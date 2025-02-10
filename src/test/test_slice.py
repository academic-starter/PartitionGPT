import os
from src.framework.slicer import Slicer
from src.framework.taint_tracking import TaintTrack
from src.test.test_dependency import generate_dependency


def test_slice():
    sensitive_vars = set(["bids"])
    pdg = generate_dependency()
    tainter = TaintTrack(pdg, sensitive_vars)
    tainter.compute()
    print("sinks:")
    for sink in tainter.get_taint_sinks():
        print(sink.node.expression)
    print("sources:")
    for sources in tainter.get_taint_sources():
        print(sources.node.expression)

    slicer = Slicer(tainter=tainter, pdg=pdg)
    pragma, cs_privates, cs_publics, other_libraries_or_external_contracts = slicer.compute_all_function_slices()
    open("private.sol", "w").write(
        "\n".join([pragma] + [cs.generate_code() for cs in cs_privates] + other_libraries_or_external_contracts))
    open("public.sol", "w").write(
        "\n".join([pragma] + [cs.generate_code() for cs in cs_publics] + other_libraries_or_external_contracts))

    cmd = "js-beautify {0} -o {0}"
    os.system(cmd.format("private.sol"))
    os.system(cmd.format("public.sol"))


if __name__ == "__main__":
    test_slice()
