from typing import Optional, List, Dict, Callable, Tuple, TYPE_CHECKING, Union, Set, Any


from crytic_compile import CryticCompile
from slither import Slither
from slither.core.compilation_unit import SlitherCompilationUnit
from slither.core.declarations.contract import Contract
from slither.core.declarations.function import Function, FunctionType, FunctionLanguage
from slither.core.declarations.modifier import Modifier
from slither.core.variables.state_variable import StateVariable


class Compilation(object):
    def __init__(self, contract_file, solc_remaps, solc_version):
        ccompile = CryticCompile(
            contract_file, solc_remaps=solc_remaps, solc_version=solc_version)
        self.slither: Slither = Slither(ccompile)

    def get_contract_from_name(self, contract_name):
        result = list(filter(lambda contract: contract.name ==
                      contract_name,  self.slither.contracts))
        assert len(result) == 1, "contract {} not found".format(contract_name)
        return result[0]

    def get_contracts_from_filename(self, file_name):
        contracts = []
        for cu in self.slither.compilation_units:
            assert isinstance(cu, SlitherCompilationUnit)
            for _file_name, _cur_scope in cu.scopes.items():
                if file_name == _file_name.absolute:
                    contracts = cu.contracts
                    return contracts
        return contracts

    def get_all_file_names(self):
        file_names = set()
        for cu in self.slither.compilation_units:
            assert isinstance(cu, SlitherCompilationUnit)
            for _file_name, _cur_scope in cu.scopes.items():
                file_names.add(_file_name.absolute)
        return file_names


class ContractWrapper(object):
    def __init__(self, target_contract_name: str, compilation: Compilation) -> None:
        self.target_contract_name: str = target_contract_name
        self.compilation: Compilation = compilation
        self.contract: Contract = self.compilation.get_contract_from_name(
            self.target_contract_name)

    def get_functions_from_name(self, func_name) -> List[Function]:
        all_match_funcs = []
        for func in self.get_functions():
            if func.name == func_name:
                all_match_funcs.append(func)
        assert len(all_match_funcs) > 0, "Function {0} not found".format(
            func_name)
        return all_match_funcs

    def get_functions(self) -> List[Function]:
        return self.contract.functions_and_modifiers

    def get_state_variable_from_name(self, name) -> StateVariable:
        all_match_vars = []
        for state_var in self.get_all_state_variables():
            if state_var.name == name:
                all_match_vars.append(state_var)
        assert len(
            all_match_vars) == 1, "State variable {0} not found".format(name)
        return all_match_vars[0]

    def get_all_state_variables(self) -> List[StateVariable]:
        return self.contract.state_variables_ordered

    def get_all_modifier_names(self) -> List[str]:
        result = []
        for modifier in self.contract.modifiers:
            result.append(modifier.name)
        return result

    def get_modifier_by_name(self, name) -> Modifier:
        for modifier in self.contract.modifiers:
            if modifier.name == name:
                return modifier
        return None
