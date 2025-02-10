# Control flow automaton
# Finding equivalent flow destinations
from typing import List, Set, Dict, Tuple
from slither.core.declarations.contract import Contract
from slither.core.declarations.function import Function, ModifierStatements
from slither.core.declarations.modifier import Modifier
from slither.core.declarations.function_contract import FunctionContract
from slither.core.variables.state_variable import StateVariable
from slither.core.cfg.node import Node, NodeType, recheable
from .program_slice import ProgramSlice


class ConditionalNode(object):
    def __init__(self, node: Node, is_true_branch: bool):
        self.node: Node = node
        self.is_true_branch: bool = is_true_branch

    @property
    def type(self):
        return self.node.type

    @property
    def source_mappping(self):
        return self.node.source_mapping


class ConditionalNodeFactory(object):
    def __init__(self) -> None:
        self.factory: List[ConditionalNode] = []

    def create_or_get_cond(self, node: Node, is_true_branch: bool):
        matched_conditionalnode = list(
            filter(lambda x: x.node == node and x.is_true_branch == is_true_branch, self.factory))
        if len(matched_conditionalnode) > 0:
            return matched_conditionalnode[0]
        else:
            conditionalnode = ConditionalNode(node, is_true_branch)
            self.factory.append(conditionalnode)
            return conditionalnode


class CFI(object):
    def __init__(self, control_path_id) -> None:
        self.id = control_path_id
        self.destinations: List[Node] = []
        self.destination_goto: List[Node] = []

    # bind a CFI id with a destination node of either normal slice or privileged slice
    def bind_destination(self, node: Node) -> None:
        self.destinations.append(node)

    # if a node is executable relies on the results whether its bined destination is triggered or not.
    def goto_destination(self, slice: ProgramSlice, node: Node) -> None:
        assert node in self.destinations
        self.destination_gotos.append([slice, node])


class CFI_Factory(object):
    def __init__(self) -> None:
        self.factory: List[CFI] = []

    def create_or_get_cfi(self, control_path_id):
        matched_cfi = list(
            filter(lambda x: x.id == control_path_id, self.factory))
        if len(matched_cfi) > 0:
            return matched_cfi[0]
        else:
            cfi = CFI(control_path_id)
            self.factory.append(cfi)
            return cfi


class CFA(object):
    def __init__(self, function: FunctionContract, normal_slice: ProgramSlice, privilege_slice: ProgramSlice) -> None:
        self.function = function
        self.normal_slice = normal_slice
        self.privilege_slice = privilege_slice
        self.cfi_factory: CFI_Factory = CFI_Factory()
        self.cond_factory: ConditionalNodeFactory = ConditionalNodeFactory()
        self.control_paths: Dict[Node, List[Node]] = dict()

    def get_shared_nodes(self) -> List[Node]:
        return set(self.normal_slice.nodes).intersection(self.privilege_slice.nodes)

    def gen_summary(self) -> str:
        self.construct_control_flow()
        shared_nodes = self.get_shared_nodes()

        summary = "Shared nodes:\n"
        for i, node in enumerate(shared_nodes):
            if node.type in [NodeType.IF, NodeType.IFLOOP, NodeType.VARIABLE, NodeType.EXPRESSION, NodeType.RETURN, NodeType.THROW]:
                summary += "#{0}: {1} {2}".format(i,
                                                  node.type,  node.source_mapping.content) + "\n"

        summary += "Uniq nodes (normal slice):\n"
        for i, node in enumerate(set(self.normal_slice.nodes).difference(shared_nodes)):
            if node.type in [NodeType.IF, NodeType.IFLOOP, NodeType.VARIABLE, NodeType.EXPRESSION, NodeType.RETURN, NodeType.THROW]:
                summary += "#{0}: {1} {2}".format(i,
                                                  node.type,  node.source_mapping.content) + "\n"

        summary += "Uniq nodes (privilege slice):\n"
        for i, node in enumerate(set(self.privilege_slice.nodes).difference(shared_nodes)):
            if node.type in [NodeType.IF, NodeType.IFLOOP, NodeType.VARIABLE, NodeType.EXPRESSION, NodeType.RETURN, NodeType.THROW]:
                summary += "#{0}: {1} {2}".format(i,
                                                  node.type,  node.source_mapping.content) + "\n"

        summary += "Equivlent nodes between normal and privileged slice:\n"
        for i, node_a in enumerate(set(self.normal_slice.nodes).difference(shared_nodes)):
            for j, node_b in enumerate(set(self.privilege_slice.nodes).difference(shared_nodes)):
                # assert node_a in self.control_paths
                # assert node_b in self.control_paths
                is_equivalent, control_path = self.control_path_equivalent(
                    node_a, node_b)
                if is_equivalent:
                    summary += "Equivlalent\n"
                    summary += "#{0}: {1} {2}".format(i,
                                                      node_a.type,  node_a.source_mapping.content) + "\n"
                    summary += "#{0}: {1} {2}".format(j,
                                                      node_b.type,  node_b.source_mapping.content) + "\n"

        # print(summary)
        cfi_policies = self.instrument_dynamic_check_CFI()

        return cfi_policies

    # explore all control paths (excecution flow)
    def dfs(self, node: Node, path: List[Node] = None) -> Set[Node]:
        if path is None:
            path = list()
        if node in path:
            return

        if node.type in [NodeType.IF, NodeType.IFLOOP]:
            if node.son_true:
                cond_node = self.cond_factory.create_or_get_cond(node, True)
                if cond_node not in path:
                    self.control_paths[node.son_true] = path + \
                        [node, cond_node]
                    self.dfs(node.son_true,
                             path=self.control_paths[node.son_true].copy())
            if node.son_false:
                cond_node = self.cond_factory.create_or_get_cond(node, False)
                if cond_node not in path:
                    self.control_paths[node.son_false] = path + \
                        [node, cond_node]
                    self.dfs(node.son_false,
                             path=self.control_paths[node.son_false].copy())
        elif node.type in [NodeType.ENDIF, NodeType.ENDLOOP]:
            for son in node.sons:
                self.control_paths[son] = path[:-2]
                if son not in path:
                    self.dfs(son, path=self.control_paths[son].copy())
        else:

            for son in node.sons:
                if son.type in [NodeType.VARIABLE, NodeType.EXPRESSION, NodeType.THROW, NodeType.RETURN, NodeType.BREAK, NodeType.CONTINUE]:
                    if son not in path:
                        if node == self.function.entry_point:
                            self.control_paths[son] = path + []
                        else:
                            self.control_paths[son] = path + [node]
                        self.dfs(son, path=self.control_paths[son].copy())
                else:
                    if son not in path:
                        self.dfs(son, path=path.copy())
        return

    def construct_control_flow(self):
        self.dfs(self.function.entry_point, [])

    # construct all control paths in combination of normal and privileged slice
    def control_path_equivalent(self, node_a: Node, node_b: Node) -> Tuple[bool, List[Node]]:
        control_path_a = list(filter(lambda node: node.type in [
            NodeType.IF, NodeType.IFLOOP], self.control_paths[node_a])) if node_a in self.control_paths else list()
        control_path_b = list(filter(lambda node: node.type in [
            NodeType.IF, NodeType.IFLOOP], self.control_paths[node_b])) if node_b in self.control_paths else list()

        return control_path_a == control_path_b, control_path_a

    def instrument_dynamic_check_CFI(self):
        # Original contract function can be divided into three parts: (normal_code_blocks, sensitive_code_blocks, normal_code_blocks)
        # Our fine-grained partioning aims to refine the sensitive code blocks by filtering non-sensitive operations to maintain the isloation of sensitive data variables from the normal data variables, thus eliminating any data movement between the normal and priviledged partitions

        # normal function's partition include: (normal_code_blocks, go_to_destinations, destinations, sensitive_code_blocks\sensitive_operations, normal_code_blocks)
        # privilege function's partition include: (destinations, sensitive_operations, goto_destinations)
        self.construct_control_flow()
        shared_nodes = self.get_shared_nodes()
        CF_reports: Dict[List[Node], Set[Node]] = dict()
        CF_checks: Dict[List[Node], Set[Node]] = dict()
        for i, node_a in enumerate(set(self.normal_slice.nodes).difference(shared_nodes)):
            for j, node_b in enumerate(set(self.privilege_slice.nodes).difference(shared_nodes)):
                is_equivlalent, control_path = self.control_path_equivalent(
                    node_a, node_b)
                if len(control_path) > 0 and is_equivlalent:
                    CF_reports[tuple(control_path)] = CF_reports.get(
                        tuple(control_path), set()).union([node_b])
                    CF_checks[tuple(control_path)] = CF_checks.get(
                        tuple(control_path), set()).union([node_a])

        cfi_policies: Dict[str, Dict[List[str]]] = dict()
        # print(">>> privilege part")
        for i, control_path in enumerate(CF_reports.keys()):
            cfi_policies["privilege"] = dict()
            for node in CF_reports[control_path]:
                # print("{0}".format(node.source_mapping.content))
                cfi_policies["privilege"][i] = cfi_policies["privilege"].get(
                    i, []) + [node.source_mapping.content]
            # print("Goto #{0}".format(i))

        # print(">>> normal part")
        for i, control_path in enumerate(CF_checks.keys()):
            # print("Label #{0}".format(i))
            cfi_policies["normal"] = dict()
            for node in CF_checks[control_path]:
                # print("{0}".format(node.source_mapping.content))
                cfi_policies["normal"][i] = cfi_policies["normal"].get(
                    i, []) + [node.source_mapping.content]
        return cfi_policies
