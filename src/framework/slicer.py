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
from slither.core.expressions.assignment_operation import AssignmentOperation
from .taint_tracking import TaintTrack
from .dependency import APINode, ProgramDependency
from .program_slice import ProgramSlice, ContractSlice
from .cfa import CFA
from .rwlock import RWLock
from src.extractor.sourcecode_catcher import SourceCodeCatcher
from src.llmpartition.code_gen import transform


class Slicer(object):
    def __init__(self, tainter: TaintTrack, pdg: ProgramDependency) -> None:
        self.tainter: TaintTrack = tainter
        self.pdg: ProgramDependency = pdg
        self.target_contract_name = self.pdg.contract.target_contract_name
        self.slices: List[ProgramSlice] = []

        locker = RWLock(self.pdg.contract)
        self.temporal_policies = locker.get_temporal_lock_policies()

    def compute_function_slice(self, function: Function, sources: Set[APINode], sinks: Set[APINode]):

        nodes_slice: List[Node] = list()

        # all operations read/write private data are sink nodes
        actual_sinks = sinks.union(sources)
        nodes_slice.extend(map(lambda sink: sink.node, actual_sinks))

        def traverse_cfg_forward(node: Node, visited: Set = None):
            if visited is None:
                visited = set()
            if node is None:
                return
            if node in visited:
                return
            visited.add(node)
            if node in nodes_slice:
                pass
            elif any([node in recheable(sink_node) and self.pdg.forward_propagation(sink_node, node) for sink_node in nodes_slice]):
                nodes_slice.append(node)
            # elif node.type in [NodeType.IF, NodeType.IFLOOP, NodeType.ENDIF, NodeType.ENDLOOP]:
            elif node.type in [NodeType.ENDIF, NodeType.ENDLOOP]:
                # we use ENDIF and ENDLOOP to maintain nested structure in the code
                # to ease the reproduction of compilable program partitions
                nodes_slice.append(node)
            else:
                pass

            for son in node.sons:
                traverse_cfg_forward(son, visited)

        def traverse_cfg_backward(node: Node, visited: Set = None):
            if visited is None:
                visited = set()
            if node is None:
                return
            if node in visited:
                return
            visited.add(node)
            if node in nodes_slice:
                pass
            elif any([sink_node in recheable(node) and self.pdg.backward_propagation(sink_node, node) for sink_node in nodes_slice]):
                nodes_slice.append(node)
            else:
                pass
            for son in node.sons:
                traverse_cfg_backward(son, visited)

        priv_nodes = nodes_slice.copy()

        # print(len(nodes_slice))
        traverse_cfg_forward(function.entry_point)
        traverse_cfg_backward(function.entry_point)
        slice1 = ProgramSlice(function, nodes_slice)

        nodes_slice = list(filter(lambda node: node.expression is not None, set(function.nodes).difference(
            nodes_slice).difference([function.entry_point]).intersection(recheable(function.entry_point))))

        # print(len(nodes_slice))
        traverse_cfg_forward(function.entry_point)
        traverse_cfg_backward(function.entry_point)
        slice2 = ProgramSlice(function, nodes_slice)

        mycfa = CFA(function=function, normal_slice=slice2,
                    privilege_slice=slice1)
        cfi_policies = mycfa.gen_summary()

        return slice1, slice2, cfi_policies, priv_nodes

    def compute_all_function_slices(self):
        sources = self.tainter.get_taint_sources()
        sinks = self.tainter.get_taint_sinks()

        critical_funcs: Set[Function] = set()
        func_sources: Dict[Function, Set[APINode]] = dict()
        for source in sources:
            critical_funcs.add(source.node.function)
            if source.node.function not in func_sources:
                func_sources[source.node.function] = set()
            func_sources[source.node.function].add(source)

        func_sinks: Dict[Function, Set[APINode]] = dict()
        for sink in sinks:
            critical_funcs.add(sink.node.function)
            if sink.node.function not in func_sinks:
                func_sinks[sink.node.function] = set()
            func_sinks[sink.node.function].add(sink)

        new_sensitive_variables = set(list(chain.from_iterable(
            [node.get_variables_write() for node in sources.union(sinks)])) + list(self.tainter.sensitive_vars))
        new_sensitive_variables = set(
            filter(lambda x: x.name != "msg.sender", new_sensitive_variables))

        ps_private_list: List[ProgramSlice] = list()
        ps_public_list: List[ProgramSlice] = list()
        all_cfi_policies: Dict[str, Dict] = dict()
        all_temporal_policies: Dict[str, Dict] = dict()
        all_partition_results = []
        for func in critical_funcs:
            if func.visibility not in ["public", "external"]:
                continue
            if func.is_constructor:
                continue
            ps1, ps2, cfi_policies, priv_nodes = self.compute_function_slice(
                func, func_sources[func] if func in func_sources else set(), func_sinks[func] if func in func_sinks else set())
            # print("Slice-1:")
            # print(str(ps1))
            # print("Slice-2:")
            # print(str(ps2))

            ps_private_list.append(ps1)
            ps_public_list.append(ps2)

            self.slices.append((ps1, ps2))
            all_cfi_policies[func.full_name] = cfi_policies

            if func.full_name in self.temporal_policies:
                all_temporal_policies[func.full_name] = self.temporal_policies[func.full_name]
            original_code, all_extern_deps = SourceCodeCatcher.get_and_gen_wrapper_contract_for_function(
                func, self.pdg.contract)

            all_sink_source_nodes: Set[Node] = set()
            all_sink_source_nodes.update(
                self.tainter.get_taint_sink_source_node_for_func(func))
            for internal_func in func.all_internal_calls():
                if isinstance(internal_func, Function):
                    all_sink_source_nodes.update(
                        self.tainter.get_taint_sink_source_node_for_func(internal_func))

            priv_nodes = set(map(lambda x: x.node, all_sink_source_nodes))

            partition_result = transform(original_code, all_extern_deps, priv_slice=ps1.generate_code(), normal_slice=ps2.generate_code(
            ), priv_nodes="\n".join([node.source_mapping.content for node in priv_nodes]), sensitive_variables=new_sensitive_variables, target_contract_name=self.target_contract_name, target_func_name=func.name)
            all_partition_results.append(partition_result)
        
        # print("Slice done.")

        for public_func in set(self.pdg.contract.contract.functions).difference(critical_funcs):
            if public_func.solidity_signature == "slitherConstructorVariables()":
                continue
            if public_func.is_implemented:
                print(public_func.name)
                ps = ProgramSlice(public_func, list(set(public_func.nodes)))
                ps_public_list.append(ps)
                print(ps)

        cs_privates = []
        cs_publics = []
        for parent_contract in self.pdg.contract.contract.inheritance_reverse:
            cs_private: ContractSlice = ContractSlice(
                parent_contract, ps_private_list)

            cs_public: ContractSlice = ContractSlice(
                parent_contract, ps_public_list)

            # will use javascript pretty printing
            # print("Contract Public")
            # print(cs_public)
            # print("Contract Private")
            # print(cs_private)
            cs_publics.append(cs_public)
            cs_privates.append(cs_private)

        cs_private: ContractSlice = ContractSlice(
            self.pdg.contract.contract, ps_private_list)

        cs_public: ContractSlice = ContractSlice(
            self.pdg.contract.contract, ps_public_list)

        cs_publics.append(cs_public)
        cs_privates.append(cs_private)

        # will use javascript pretty printing
        # print("Contract Public")
        # print(cs_public)
        # print("Contract Private")
        # print(cs_private)

        other_libraries_or_external_contracts = [contract.source_mapping.content for contract in set(self.pdg.contract.compilation.slither.contracts).difference(
            self.pdg.contract.contract.inheritance).difference([self.pdg.contract.contract])]

        pragma = list(self.pdg.contract.contract.file_scope.pragmas)[
            0].source_mapping.content
        return pragma, cs_privates, cs_publics, other_libraries_or_external_contracts, all_cfi_policies, all_temporal_policies, all_partition_results
