
from itertools import chain
from typing import List
from slither.core.declarations import FunctionContract, Contract
from slither.core.cfg.node import Node
from slither.core.declarations import SolidityFunction
from slither.core.solidity_types.type import Type
from src.framework.compile import Compilation, ContractWrapper


class SourceCodeCatcher:
    def include_only_contracts(included_contracts: List[Contract]):
        # TODO: assume all contracts are stored in the same file
        compilation_unit = included_contracts[0].compilation_unit
        excluded_contracts = [
            contract for contract in compilation_unit.contracts if contract not in included_contracts]

        in_file = included_contracts[0].source_mapping.filename.absolute
        # Retrieve the source code
        in_file_str = compilation_unit.core.source_code[in_file]

        for excluded_contract in excluded_contracts:
            code = SourceCodeCatcher.get_contract_code(excluded_contract)
            # print("Excluded code: {0}".format(code))
            # code = excluded_contract.source_mapping.content
            in_file_str = in_file_str.replace(code, "")
            # print(in_file_str)
        return in_file_str

    def get_function_code(func: FunctionContract):
        in_file = func.contract.source_mapping.filename.absolute
        # Retrieve the source code
        in_file_str = func.contract.compilation_unit.core.source_code[in_file]

        # Get the string
        start = func.source_mapping.start
        stop = start + func.source_mapping.length
        return in_file_str[start:stop]

    def get_contract_code(contract: Contract):
        # in_file = contract.source_mapping.filename.absolute
        # # Retrieve the source code
        # in_file_str = contract.compilation_unit.core.source_code[in_file]

        # start = contract.source_mapping.start
        # stop = contract.source_mapping.length
        # return in_file_str[start:stop]
        return contract.source_mapping.content

    def get_node_code(node: Node):
        return str(node)

    def get_function_full_context(function: FunctionContract, wrapper: ContractWrapper, visited: List = None):
        if not function.is_implemented:
            return []
        if visited is None:
            visited = []
        if function in visited:
            return []
        visited.append(function)
        code = []
        code.append(SourceCodeCatcher.get_function_code(function))
        for internal_call in function.internal_calls:
            if internal_call.name in wrapper.get_all_modifier_names():
                modifier = wrapper.get_modifier_by_name(internal_call.name)
                code.extend(SourceCodeCatcher.get_function_full_context(
                    modifier, wrapper, visited))
            elif isinstance(internal_call, SolidityFunction):
                continue
            else:
                internal_funcs = wrapper.get_functions_from_name(
                    internal_call.name)
                for internal_func in internal_funcs:
                    code.extend(SourceCodeCatcher.get_function_full_context(
                        internal_func, wrapper, visited))
        return code

    def get_function_full_context_raw(function: FunctionContract, wrapper: ContractWrapper, visited: List = None):
        if not function.is_implemented:
            return []
        if visited is None:
            visited = []
        if function in visited:
            return []
        visited.append(function)
        code = []
        code.append(function)
        for internal_call in function.internal_calls:
            if internal_call.name in wrapper.get_all_modifier_names():
                modifier = wrapper.get_modifier_by_name(internal_call.name)
                code.extend(SourceCodeCatcher.get_function_full_context_raw(
                    modifier, wrapper, visited))
            elif isinstance(internal_call, SolidityFunction):
                continue
            else:
                internal_funcs = wrapper.get_functions_from_name(
                    internal_call.name)
                for internal_func in internal_funcs:
                    code.extend(SourceCodeCatcher.get_function_full_context_raw(
                        internal_func, wrapper, visited))
        return code

    def get_and_gen_wrapper_contract_for_function(function: FunctionContract, wrapper: ContractWrapper):
        code: List[FunctionContract] = SourceCodeCatcher.get_function_full_context_raw(
            function, wrapper)

        contract_declaration = "{abstract} contract {name}".format(
            abstract="", name=wrapper.contract.name)

        all_used_state_variables = set(list(chain.from_iterable(
            [subfunc.all_state_variables_read() + subfunc.all_state_variables_written() for subfunc in code])))

        # assert len(
        #     all_used_state_variables) > 0, "None of state variables are used"

        # generate function or modifier codes
        function_codes = [SourceCodeCatcher.get_function_code(subfunc)
                          for subfunc in code]

        # generate state variable declarations
        state_variables_declarations = [
            state_var.source_mapping.content + ";" for state_var in all_used_state_variables]

        # generate structure types declarations
        struct_types_declarations = [
            structure.source_mapping.content for structure in wrapper.contract.structures]
        
        enum_types_declarations = [
            enum.source_mapping.content for enum in wrapper.contract.enums]

        # using statements
        using_statements = ["using {0} for {1};".format(using_for_key.type.replace("\n", ""), ",".join([str(item.type.name) if isinstance(item, Type) else item.name for item in wrapper.contract.using_for[using_for_key]]))
                            for using_for_key in wrapper.contract.using_for
                            ]
        if wrapper.contract.using_for_complete is not None:
            using_statements.extend(["using {0} for *;".format(using_for_key.type.replace("\n", ""))
                                     for using_for_key in wrapper.contract.using_for_complete
                                     ])
            # if len(using_statements) > 0:
            #     print(using_statements)
            # generate event codes
            event_codes = [event.source_mapping.content
                           for event in wrapper.contract.events]

            # generate error codes
            error_codes = [error.source_mapping.content
                           for error in wrapper.contract.custom_errors]

            # we assume that all contract code is flattened into a single file and there is only one pragma declaration

            # contract_code = "{contract_declaration}{{\n{using_statements} {state_variables_declarations}\n{struct_types_declarations}\n{event_codes}\n{error_codes}\n{function_codes}}}".format(contract_declaration=contract_declaration, using_statements="\n".join(using_statements), state_variables_declarations="\n".join(
            #     state_variables_declarations), struct_types_declarations="\n".join(struct_types_declarations), function_codes="\n\n".join(function_codes), event_codes="\n".join(event_codes), error_codes="\n".join(error_codes))
            
            contract_code = "{contract_declaration}{{\n{enum_types_declarations} {state_variables_declarations}\n{struct_types_declarations}\n{event_codes}\n{error_codes}\n{function_codes}}}".format(contract_declaration=contract_declaration, enum_types_declarations="\n".join(enum_types_declarations), state_variables_declarations="\n".join(
                state_variables_declarations), struct_types_declarations="\n".join(struct_types_declarations), function_codes="\n\n".join(function_codes), event_codes="\n".join(event_codes), error_codes="\n".join(error_codes))

            all_lib_callss = [f.all_library_calls()
                              for f in code]  # type: ignore
            all_lib_calls = list(
                set([item for sublist in all_lib_callss for item in sublist]))
            used_libraries: List[Contract] = []
            for lib_call in all_lib_calls:
                lib_contract, lib_func = lib_call
                used_libraries.append(lib_contract)

            used_libaries_code = "\n".join(
                [SourceCodeCatcher.get_contract_code(lib) for lib in used_libraries])

            all_high_level_callss = [f.all_high_level_calls()
                                     for f in code]  # type: ignore
            all_high_level_calls = list(
                set([item for sublist in all_high_level_callss for item in sublist]))

            used_externs: List[Contract] = []
            for high_level_call in all_high_level_calls:
                external_contract, func_or_var = high_level_call
                used_externs.append(external_contract)
            used_external_code = "\n".join(
                [SourceCodeCatcher.get_contract_code(contract) for contract in used_externs])

            def get_external_deps(contract: Contract, visited=None) -> List[Contract]:
                if visited is None:
                    visited = []
                if contract in visited:
                    return []
                visited.append(contract)
                inheritance: List[Contract] = contract.inheritance_reverse
                all_externs: List[Contract] = [high_level_call[0]
                                               for high_level_call in contract.all_high_level_calls]
                all_libs: List[Contract] = [high_level_call[0]
                                            for high_level_call in contract.all_library_calls]
                results = list(set(inheritance + all_externs + all_libs))
                for item in results.copy():
                    results.extend(get_external_deps(item, visited))
                return list(set(results))

            all_extern_deps = list(set(chain.from_iterable(
                [get_external_deps(item) for item in used_libraries + used_externs])))

            all_extern_deps = list(
                set(used_libraries + used_externs + all_extern_deps))

            all_extern_deps_names = [item.name for item in all_extern_deps]

            if len(all_extern_deps) > 0:
                all_extern_deps_code = SourceCodeCatcher.include_only_contracts(
                    all_extern_deps)
            else:
                all_extern_deps_code = None
            return contract_code, all_extern_deps_code
