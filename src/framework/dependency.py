from typing import List, Set, Dict
from typing_extensions import Self
from slither.core.cfg.node import Node, NodeType, recheable
from slither.analyses.data_dependency.data_dependency import is_dependent
from .compile import ContractWrapper, Function


class PDGNode:
    def __init__(self, node: Node):
        self.node: Node = node
        self.sons: List[Self] = []
        self.fathers: Set[Self] = set()

    def get_state_variables_reads(self):
        return self.node.state_variables_read

    def get_state_variables_written(self):
        return self.node.state_variables_written

    def get_local_variables_reads(self):
        return self.node.local_variables_read

    def get_local_variables_written(self):
        return self.node.local_variables_written

    def get_variables_read(self):
        return self.node.variables_read

    def get_variables_write(self):
        return self.node.variables_written


class APINode(PDGNode):
    def __init__(self, node: Node, dependency_type: str = "ControlDep"):
        super().__init__(node)
        self.dependency_type = dependency_type

    def add_son(self, son: Self):
        if self.dependency_type == "ControlDep":
            print("[{0}]{1} -> {2}".format(self.dependency_type,
                                           self.node.expression, son.node.expression))
        else:
            print("[{0}]{1} -> {2}".format(self.dependency_type,
                                           self.node.expression, son.node.expression))
        self.sons.append(son)
        son.add_father(self)

    def add_father(self, father: Self):
        self.fathers.add(father)


class SingletonAPINodeFactory(object):
    def __init__(self) -> None:
        self.apinodes: List[APINode] = []

    def create_or_get_node(self, node: Node, dependency_type: str = "ControlDep") -> APINode:
        result = list(
            filter(lambda apinode: apinode.node == node, self.apinodes))
        if len(result) == 1:
            return result[0]
        else:
            assert len(result) == 0
            apinode = APINode(node, dependency_type=dependency_type)
            self.apinodes.append(apinode)
            return apinode


class ControlPDG(object):
    def __init__(self, function: Function) -> None:
        self.function: Function = function
        self.factory: SingletonAPINodeFactory = SingletonAPINodeFactory()

    def generate(self):
        def traverse_cfg(node, cur_conditional_nodes: List[Node] = [], visited: Set[Node] = set()):
            if node is None:
                return
            if node in visited:
                return
            visited.add(node)
            if node.type == NodeType.EXPRESSION and node.contains_require_or_assert():
                apinode = self.factory.create_or_get_node(node)
                if len(cur_conditional_nodes) == 0:
                    cur_conditional_nodes.append(node)
                else:
                    cur_conditional_node = cur_conditional_nodes[-1]
                    pre_apinode = self.factory.create_or_get_node(
                        cur_conditional_node, dependency_type="ControlDep")
                    pre_apinode.add_son(apinode)
                    cur_conditional_nodes.append(node)

                cur_conditional_nodes_new = cur_conditional_nodes.copy()
                for son in node.sons:
                    traverse_cfg(son, cur_conditional_nodes_new, visited)
            elif node.type in [NodeType.IF, NodeType.IFLOOP]:
                apinode = self.factory.create_or_get_node(node)
                if len(cur_conditional_nodes) == 0:
                    cur_conditional_nodes.append(node)
                else:
                    cur_conditional_node = cur_conditional_nodes[-1]
                    pre_apinode = self.factory.create_or_get_node(
                        cur_conditional_node, dependency_type="ControlDep")
                    pre_apinode.add_son(apinode)
                    cur_conditional_nodes.append(node)

                cur_conditional_nodes_new = cur_conditional_nodes.copy()
                if node.son_true:
                    traverse_cfg(
                        node.son_true, cur_conditional_nodes_new.copy(), visited)
                if node.son_false:
                    traverse_cfg(node.son_false,
                                 cur_conditional_nodes_new.copy(), visited)
            elif node.type in [NodeType.ENDIF, NodeType.ENDLOOP]:
                cur_conditional_nodes_new = cur_conditional_nodes.copy()
                cur_conditional_nodes_new.pop()
                for son in node.sons:
                    traverse_cfg(son, cur_conditional_nodes_new, visited)
            else:
                if len(cur_conditional_nodes) != 0:
                    cur_conditional_node = cur_conditional_nodes[-1]
                    apinode = self.factory.create_or_get_node(
                        node, dependency_type="ControlDep")
                    pre_apinode = self.factory.create_or_get_node(
                        cur_conditional_node, dependency_type="ControlDep")
                    pre_apinode.add_son(apinode)

                for son in node.sons:
                    traverse_cfg(son, cur_conditional_nodes.copy(), visited)
        traverse_cfg(self.function.entry_point)

    @property
    def nodes(self):
        return self.factory.apinodes


class DataPDG(object):
    def __init__(self, function: Function) -> None:
        self.function: Function = function
        self.factory: SingletonAPINodeFactory = SingletonAPINodeFactory()

    def generate(self) -> None:
        # TODO: support more fine-grained control over data dependencies
        for i, node_a in enumerate(self.function.nodes):
            apinode_a = self.factory.create_or_get_node(
                node_a, dependency_type="DataDep")
            for j, node_b in enumerate(self.function.nodes):
                if i == j:
                    continue
                if not self.is_reachable(node_a, node_b):
                    continue
                apinode_b = self.factory.create_or_get_node(
                    node_b, dependency_type="DataDep")
                if self.is_dependent(left=apinode_a, right=apinode_b):
                    apinode_a.add_son(apinode_b)

    def is_reachable(self, left: Node, right: Node, visited=set()):
        # FIXME: this current implementation seems not work
        # I need to figure out the reason

        return right in recheable(left)

    def is_dependent(self, left: APINode, right: APINode):
        left_variable_writes = left.get_variables_write()
        # if len(left_variable_writes) == 0 and left.node.type == NodeType.VARIABLE:
        #     assert left.node.variable_declaration is not None
        #     left_variable_writes = [left.node.variable_declaration]
        right_variable_reads = right.get_variables_read()

        # return any([is_dependent(pair[0], pair[1], self.function) for pair in zip(left_variable_reads, right_variable_writes)])
        return len(set(left_variable_writes).intersection(right_variable_reads)) > 0

    @property
    def nodes(self):
        return self.factory.apinodes


class ProgramDependency(object):
    def __init__(self, contract: ContractWrapper):
        self.contract: ContractWrapper = contract
        self.control_dependencies: Dict[Function, ControlPDG] = dict()
        self.data_dependencies: Dict[Function, DataPDG] = dict()

    def generate_dependencies(self):
        for function in self.contract.get_functions():
            if not function.pure:
                print("**************************")
                print(function.name)
                data_pdg = DataPDG(function)
                data_pdg.generate()

                self.data_dependencies[function] = data_pdg

                control_pdg = ControlPDG(function)
                control_pdg.generate()

                self.control_dependencies[function] = control_pdg

    def get_datadep_apinode(self, function: Function, node: Node) -> List[APINode]:
        nodes = list(filter(
            lambda apinode: apinode.node == node,  self.data_dependencies[function].nodes))
        return nodes

    def get_controldep_apinode(self, function: Function, node: Node) -> List[APINode]:
        nodes = list(filter(
            lambda apinode: apinode.node == node,  self.control_dependencies[function].nodes))
        return nodes

    # later we will add some cache support to speed up the analysis
    # backward propagation gather data dependencies and control dependencies to produce compilable program slice
    def backward_propagation(self, left: Node, right: Node, visited: Set = None):
        if visited is None:
            visited = set()
        if (left, right) in visited:
            return False
        visited.add((left, right))
        assert left.function == right.function, "Function mismatch"
        left_datadep_apinodes = self.get_datadep_apinode(left.function, left)
        right_datadep_apinodes = self.get_datadep_apinode(
            right.function, right)
        left_controldep_apinodes = self.get_controldep_apinode(
            left.function, left)
        right_controldep_apinodes = self.get_controldep_apinode(
            right.function, right)

        assert len(left_datadep_apinodes) <= 1 and len(
            right_datadep_apinodes) <= 1

        if len(left_datadep_apinodes) == 1 and len(right_datadep_apinodes) == 1:

            if left_datadep_apinodes[0] in right_datadep_apinodes[0].sons:
                return True
            else:
                for son in right_datadep_apinodes[0].sons:
                    if self.backward_propagation(left, son.node, visited):
                        return True

        if len(left_controldep_apinodes) == 1 and len(right_controldep_apinodes) == 1:

            if left_controldep_apinodes[0] in right_controldep_apinodes[0].sons:
                return True
            else:
                for son in right_controldep_apinodes[0].sons:
                    if self.backward_propagation(left, son.node, visited):
                        return True
        return False

    # foward propagation only gather more data nodes that flow out of the sinks
    def forward_propagation(self, left: Node, right: Node, visited: Set = None):
        if visited is None:
            visited = set()
        if (left, right) in visited:
            return False
        visited.add((left, right))
        assert left.function == right.function, "Function mismatch"
        left_datadep_apinodes = list(filter(
            lambda apinode: apinode.node == left,  self.data_dependencies[left.function].nodes))
        right_datadep_apinodes = list(filter(
            lambda apinode: apinode.node == right,  self.data_dependencies[right.function].nodes))
        left_controldep_apinodes = list(filter(
            lambda apinode: apinode.node == left,  self.control_dependencies[left.function].nodes))
        right_controldep_apinodes = list(filter(
            lambda apinode: apinode.node == right,  self.control_dependencies[right.function].nodes))

        if len(left_datadep_apinodes) == 1 and len(right_datadep_apinodes) == 1:

            if right_datadep_apinodes[0] in left_datadep_apinodes[0].sons:
                return True
            else:
                for son in left_datadep_apinodes[0].sons:
                    if self.forward_propagation(son.node, right, visited):
                        return True

        # if len(left_controldep_apinodes) == 1 and len(right_controldep_apinodes) == 1:
        #     if right_controldep_apinodes[0] in left_controldep_apinodes[0].sons:
        #         return True
        #     else:
        #         for son in left_controldep_apinodes[0].sons:
        #             if self.depend_on_with_forward_propagation(son.node, right, visited):
        #                 return True
        return False
