from src.framework.dependency import ProgramDependency
from src.extractor.benchmark_compile import compile


def generate_dependency():
    wrapper = compile()
    pdg = ProgramDependency(contract=wrapper)
    pdg.generate_dependencies()
    return pdg


if __name__ == "__main__":
    generate_dependency()
