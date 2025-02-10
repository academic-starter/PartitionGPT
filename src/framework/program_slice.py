# This python script is used to generate compilable program partitions.
# We will consider many practical factors.
# In a program slice, all pertinent nodes are recorded and well-organized.
import re
from typing import List, Set, Dict
from itertools import chain
from slither.core.declarations.contract import Contract
from slither.core.declarations.function import Function, ModifierStatements
from slither.core.declarations.modifier import Modifier
from slither.core.declarations.function_contract import FunctionContract
from slither.core.variables.state_variable import StateVariable
from slither.core.cfg.node import Node, NodeType, recheable
from slither.core.solidity_types.type import Type
from slither.core.expressions import ConditionalExpression


class ProgramSlice(object):
    def __init__(self, function: FunctionContract, nodes: List[Node]) -> None:
        self.function: FunctionContract = function
        self.nodes: List[Node] = nodes

    def __str__(self) -> str:
        # return "slice(" + self.function.name + "):\n" + "\n".join(map(str, self.nodes))
        return "slice(" + self.function.name + "):\n" + self.generate_code()

    def get_used_modifiers(self) -> List[Modifier]:
        used_modifiers: List[Modifier] = []
        modifier_statements: List[ModifierStatements] = self.function.modifiers_statements
        for modifier_statement in modifier_statements:
            if any([str(node.expression).find(modifier_statement.nodes[-1].source_mapping.content) != -1 for node in self.nodes]):
                used_modifiers.append(modifier_statement.modifier)

        return used_modifiers

    def get_used_state_variables(self) -> List[StateVariable]:
        used_modifiers: List[Modifier] = self.get_used_modifiers()
        used_state_variables: List[StateVariable] = []
        for node in self.nodes:
            used_state_variables.extend(node.state_variables_read)
            used_state_variables.extend(node.state_variables_written)

        for modifier in used_modifiers:
            used_state_variables.extend(modifier.state_variables_read)
            used_state_variables.extend(modifier.state_variables_written)
        return used_state_variables

    def generate_code(self) -> str:
        used_modifier_names = [
            modifier.name for modifier in self.get_used_modifiers()]
        inheritance_names = [
            parent.name for parent in self.function.contract_declarer.inheritance]
        default_names = used_modifier_names + inheritance_names

        all_lines = self.function.source_mapping.lines
        code: Dict[int, str] = dict()

        line_codes = open(
            self.function.source_mapping.filename.absolute).readlines()

        avoid_repeated_conditional_node_output: Set[str] = set()

        for k, node in enumerate(self.function.nodes_ordered_dominators):
            if node in self.nodes:
                if node.type in [NodeType.IF, NodeType.IFLOOP]:
                    starting_column = node.source_mapping.starting_column-1
                    ending_column = node.source_mapping.ending_column-1
                    assert starting_column >= 0 and ending_column >= 0
                    lines = node.source_mapping.lines
                    # if isinstance(node.expression, ConditionalExpression):
                    if node.son_false is not None and node.son_true is not None and (node.source_mapping.content == node.son_true.source_mapping.content and node.source_mapping.content == node.son_false.source_mapping.content):
                        if node.son_false in self.nodes:
                            self.nodes.remove(node.son_false)
                        if node.son_true in self.nodes:
                            self.nodes.remove(node.son_true)
                        avoid_repeated_conditional_node_output.add(
                            node.source_mapping.content)
                        prefix = ""
                        for i, line in enumerate(lines):
                            if i == 0:
                                if len(lines) == 1:
                                    code[line] = code.get(
                                        line, "") + prefix + line_codes[line-1][starting_column:ending_column] + ";"
                                else:
                                    code[line] = code.get(
                                        line, "") + prefix + line_codes[line-1][starting_column:]
                            elif i == len(lines)-1:
                                code[line] = code.get(
                                    line, "") + line_codes[line-1][:ending_column] + ";"
                            else:
                                code[line] = line_codes[line-1]
                            assert True
                    else:
                        prefix = "if (" if node.type == NodeType.IF else "for ("
                        for i, line in enumerate(lines):
                            if i == 0:
                                if len(lines) == 1:
                                    code[line] = code.get(
                                        line, "") + prefix + line_codes[line-1][starting_column:ending_column] + ") {"
                                else:
                                    code[line] = code.get(
                                        line, "") + prefix + line_codes[line-1][starting_column:]
                            elif i == len(lines)-1:
                                code[line] = code.get(
                                    line, "") + line_codes[line-1][:ending_column] + ") {"
                            else:
                                code[line] = line_codes[line-1]
                            assert True

                        if node.type == NodeType.IF:
                            if node.son_false is not None and node.son_false.expression is not None:
                                # enable `}else{` since there is no node indicating it.
                                else_node_start_line = node.son_false.source_mapping.lines[0]
                                code[else_node_start_line] = code.get(
                                    else_node_start_line, "") + "} else { "

                elif node.type in [NodeType.ENDIF, NodeType.ENDLOOP]:
                    # if isinstance(node.expression, ConditionalExpression):
                    if node.source_mapping.content in avoid_repeated_conditional_node_output:
                        continue
                    starting_column = node.source_mapping.starting_column-1
                    ending_column = node.source_mapping.ending_column-1
                    assert starting_column >= 0 and ending_column >= 0
                    lines = node.source_mapping.lines
                    if any([line in code for line in lines]):
                        code[lines[-1]] = code.get(lines[-1], "") + "}"

                else:
                    if node.type in [NodeType.VARIABLE, NodeType.EXPRESSION, NodeType.RETURN, NodeType.THROW]:
                        if node.source_mapping.content in avoid_repeated_conditional_node_output:
                            continue
                        starting_column = node.source_mapping.starting_column-1
                        ending_column = node.source_mapping.ending_column-1
                        assert starting_column >= 0 and ending_column >= 0
                        lines = node.source_mapping.lines
                        for i, line in enumerate(lines):
                            if i == 0:
                                if len(lines) == 1:
                                    code[line] = code.get(
                                        line, "") + line_codes[line-1][starting_column:ending_column] + " "
                                    if not any([re.match("{0}[\(|\s]+".format(name), code[line]) for name in default_names]):
                                        code[line] = code[line] + ";"
                                else:
                                    code[line] = code.get(
                                        line, "") + line_codes[line-1][starting_column:] + " "
                            elif i == len(lines)-1:
                                code[line] = code.get(
                                    line, "") + line_codes[line-1][:ending_column] + " "
                                if not any([re.match("{0}[\(|\s]+".format(name), code[line]) for name in default_names]):
                                    # if not any([code[line].find(name) != -1 for name in default_names]):
                                    code[line] = code[line] + ";"
                            else:
                                code[line] = code.get(
                                    line, "") + line_codes[line-1] + " "
                            assert True

        text = self.function.source_mapping.content
        body_start = text.find("{")
        func_header = text[:body_start]

        # modifier removal
        modifier_statements = self.function.modifiers_statements
        for modifier in modifier_statements:
            func_header = func_header.replace(
                modifier.nodes[-1].source_mapping.content, "")

        starting_column = self.function.entry_point.source_mapping.starting_column-1
        ending_column = self.function.entry_point.source_mapping.ending_column-1
        lines = self.function.entry_point.source_mapping.lines

        func_header = func_header.replace(code.get(lines[0], ""), "")

        unclosed_branch_brackets = len(list(filter(lambda x: x.type == NodeType.IF, self.nodes))) - len(
            list(filter(lambda x: x.type == NodeType.ENDIF, self.nodes)))

        code[lines[0]] = code.get(lines[0], "") + " {"
        code[lines[-1]] = code.get(lines[-1], "") + "}" if unclosed_branch_brackets == 0 else code.get(
            lines[-1], "") + "}" + " ".join(["}"]*unclosed_branch_brackets)

        plain_code = ""
        for line in all_lines:
            if line in code:
                plain_code += code[line] + "\n"

        return func_header + "\n" + plain_code


class ContractSlice(object):
    def __init__(self, contract: Contract, ps_list: List[ProgramSlice]):
        self.contract: Contract = contract
        self.ps_list: List[ProgramSlice] = ps_list

    def __str__(self) -> str:
        return self.generate_code()

    def generate_code(self) -> str:
        contract_code = ""
        # generate contract declarations containing inheriting, abstract
        if len(self.contract.immediate_inheritance) > 0:
            contract_declaration = "{abstract} contract {name} is {inherits}".format(
                abstract="abstract" if self.contract.constructors_declared is None else "", name=self.contract.name, inherits=",".join([parent.name for parent in self.contract.immediate_inheritance]))
        else:
            contract_declaration = "{abstract} contract {name}".format(
                abstract="", name=self.contract.name)

        all_used_state_variables = set(list(chain.from_iterable(
            [ps.get_used_state_variables() for ps in self.ps_list if ps.function.contract_declarer == self.contract and ps.function.solidity_signature != "slitherConstructorVariables()"])))

        if len(all_used_state_variables) > 0:
            # generate function codes
            function_codes = [ps.generate_code()
                              for ps in self.ps_list if ps.function.contract_declarer == self.contract and ps.function.solidity_signature != "slitherConstructorVariables()"]
            all_used_modifiers = set(list(chain.from_iterable(
                [ps.get_used_modifiers() for ps in self.ps_list if ps.function.contract_declarer == self.contract and ps.function.solidity_signature != "slitherConstructorVariables()"])))
            # generate function codes
            modifier_codes = [modifier.source_mapping.content
                              for modifier in self.contract.modifiers_declared if modifier.canonical_name in set(map(lambda used_modifier: used_modifier.canonical_name, all_used_modifiers))]
            # generate state variable declarations
            state_variables_declarations = [
                state_var.source_mapping.content + ";" for state_var in self.contract.state_variables_declared if state_var in all_used_state_variables]

            # generate structure types declarations
            struct_types_declarations = [
                structure.source_mapping.content for structure in self.contract.structures_declared]

            # using statements
            using_statements = ["using {0} for {1};".format(using_for_key.type.replace("\n", ""), ",".join([str(item.type.name) if isinstance(item, Type) else item.name for item in self.contract.using_for[using_for_key]]))
                                for using_for_key in self.contract.using_for
                                ]
            if self.contract.using_for_complete is not None:
                using_statements.extend(["using {0} for *;".format(using_for_key.type.replace("\n", ""))
                                        for using_for_key in self.contract.using_for_complete
                                         ])
            if len(using_statements) > 0:
                print(using_statements)
            # generate event codes
            event_codes = [event.source_mapping.content
                           for event in self.contract.events_declared]

            # generate error codes
            error_codes = [error.source_mapping.content
                           for error in self.contract.custom_errors_declared]

            # we assume that all contract code is flattened into a single file and there is only one pragma declaration

            contract_code = "{contract_declaration}{{\n{using_statements} {state_variables_declarations}\n{struct_types_declarations}\n{event_codes}\n{error_codes}\n{function_codes}\n{modifier_codes}}}".format(contract_declaration=contract_declaration, using_statements="\n".join(using_statements), state_variables_declarations="\n".join(
                state_variables_declarations), struct_types_declarations="\n".join(struct_types_declarations), function_codes="\n\n".join(function_codes), modifier_codes="\n\n".join(modifier_codes), event_codes="\n".join(event_codes), error_codes="\n".join(error_codes))
            return contract_code
        else:
            # empty sensitive state variable set, indicating this contract is not related to privacy protection
            # this contract is likely to be third party libraries that user own contract inherit or used.
            # kept the whole contract code
            # FIXME: this will increase the codebase size of deployed private contract
            contract_code = self.contract.source_mapping.content
            return contract_code
