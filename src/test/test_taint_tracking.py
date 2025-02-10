from src.framework.taint_tracking import TaintTrack
from src.test.test_dependency import generate_dependency


def taint_tracking():
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


if __name__ == "__main__":
    taint_tracking()
