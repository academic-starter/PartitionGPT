from typing import List, Set, Union

from slither.core.variables.variable import Variable
from slither.analyses.data_dependency.data_dependency import is_dependent
from slither.core.declarations.function import Function
from .dependency import ProgramDependency, ContractWrapper, APINode

# TODO: Currently we don't support propogation of taint analysis


class TaintSources(object):
    def __init__(self, pdg: ProgramDependency, sensitive_vars: Set[Variable] = set()) -> None:
        self.pdg = pdg
        self.sensitive_vars = sensitive_vars
        self.sources: Set[APINode] = set()

    def is_dependent(self, sensitive_var: Variable, node: APINode) -> bool:
        for variables_read in node.get_variables_read():
            if variables_read is not None and variables_read.name not in ["msg.sender", "msg.value", "block.timestamp", "block.number", "msg.gas"]:
                if is_dependent(variables_read, sensitive_var, self.pdg.contract.contract):
                    return True

        for variables_write in node.get_variables_write():
            if is_dependent(variables_write, sensitive_var, self.pdg.contract.contract):
                return True

        for variable in node.get_variables_read():
            if variable == sensitive_var:
                return True

        for variable in node.get_variables_write():
            if variable == sensitive_var:
                return True

        for internal_call in node.node.internal_calls:
            if isinstance(internal_call, Function):
                for _node in internal_call.nodes:
                    if self.is_dependent(sensitive_var,  APINode(_node,dependency_type=None)):
                        return True 

      
        return False

    def forward_analysis(self) -> None:
        for func in self.pdg.data_dependencies:
            for node in self.pdg.data_dependencies[func].nodes:
                for sensitive_var in self.sensitive_vars:
                    if self.is_dependent(sensitive_var=sensitive_var, node=node):
                        self.sources.add(node)
                        break

    def get_taint_sources(self) -> Set[APINode]:
        return self.sources


class TaintSinks(object):
    def __init__(self, pdg: ProgramDependency, sensitive_vars: Set[Variable] = set()) -> None:
        self.pdg = pdg
        self.sensitive_vars = sensitive_vars
        self.sinks: Set[APINode] = set()

    def is_dependent(self, sensitive_var: Variable, node: APINode) -> bool:
        for variables_read in node.get_variables_read():
            if variables_read is not None and variables_read.name not in ["msg.sender", "msg.value", "block.timestamp", "block.number", "msg.gas"]:
                if is_dependent(sensitive_var, variables_read, self.pdg.contract.contract):
                    return True

        for variables_write in node.get_variables_write():
            if is_dependent(sensitive_var, variables_write, self.pdg.contract.contract):
                return True

        for variable in node.get_variables_read():
            if variable == sensitive_var:
                return True

        for variable in node.get_variables_write():
            if variable == sensitive_var:
                return True
        
        for internal_call in node.node.internal_calls:
            if isinstance(internal_call, Function):
                for _node in internal_call.nodes:
                    if self.is_dependent(sensitive_var,  APINode(_node,dependency_type=None)):
                        return True 

        return False

    def backward_analysis(self) -> None:
        for func in self.pdg.data_dependencies:
            for node in self.pdg.data_dependencies[func].nodes:
                for sensitive_var in self.sensitive_vars:
                    if self.is_dependent(sensitive_var=sensitive_var, node=node):
                        self.sinks.add(node)
                        break

    def get_taint_sinks(self) -> Set[APINode]:
        return self.sinks


class TaintTrack(object):
    def __init__(self, pdg: ProgramDependency, sensitive_var_names: Set[Union[str | Variable]]) -> None:
        assert pdg is not None
        assert sensitive_var_names is not None and len(
            sensitive_var_names) > 0, "No sensitive variables are provided"

        if isinstance(list(sensitive_var_names)[0], Variable):
            sensitive_vars = sensitive_var_names
        else:
            sensitive_vars: Set[str] = set()
            for var_name in sensitive_var_names:
                sensitive_vars.add(
                    pdg.contract.get_state_variable_from_name(var_name))

        self.taintsources = TaintSources(pdg, sensitive_vars)
        self.taintsinks = TaintSinks(pdg, sensitive_vars)
        self.sensitive_vars = sensitive_vars

    def compute(self):
        self.taintsources.forward_analysis()
        self.taintsinks.backward_analysis()

    def get_taint_sources(self) -> Set[APINode]:
        return self.taintsources.get_taint_sources()

    def get_taint_sinks(self) -> Set[APINode]:
        return self.taintsinks.get_taint_sinks()

    def get_taint_sink_source_node_for_func(self, func: Function):
        result: Set = set()

        for source in self.taintsources.get_taint_sources():
            if source.node.function == func:
                result.add(source)

        for sink in self.taintsinks.get_taint_sinks():
            if sink.node.function == func:
                result.add(sink)

        for internal_call in func.all_internal_calls():
            if isinstance(internal_call, Function):
                result.update(
                    self.get_taint_sink_source_node_for_func(internal_call))

        for c in func.modifiers_statements:
            result.update(self.get_taint_sink_source_node_for_func(c.modifier))

        return result
