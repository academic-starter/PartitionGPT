# read/write lock on state variables
from typing import Dict, List, Set
import itertools
from .compile import ContractWrapper, Function


class RWLock(object):
    def __init__(self, contractwrapper: ContractWrapper):
        self.wrapper = contractwrapper
        self.statevariable_readers: Dict[str, Set[Function]] = dict()
        self.statevariable_writers: Dict[str, Set[Function]] = dict()
        self.atomic_locks: Dict[str, List[str]] = dict()

    def initialize_readers_writers(self):
        for function in self.wrapper.get_functions():
            if function.is_constructor or function.name == "slitherConstructorVariables" or function.visibility not in ["public", "external"]:
                continue
            for state_variable in function.all_state_variables_read():
                var_name = state_variable.name
                self.statevariable_readers[var_name] = self.statevariable_readers.get(
                    var_name, set()).union([function])

            for state_variable in function.all_state_variables_written():
                var_name = state_variable.name
                self.statevariable_writers[var_name] = self.statevariable_writers.get(
                    var_name, set()).union([function])

    def create_tempory_lock_policy(self):
        for state_variable in self.statevariable_readers:
            if state_variable in self.statevariable_writers:
                for pair in itertools.product(self.statevariable_readers[state_variable], self.statevariable_writers[state_variable]):
                    left, right = pair
                    if left == right:
                        continue
                    else:
                        self.atomic_locks[left.full_name] = list(set(self.atomic_locks.get(
                            left.full_name, list())).union([right.full_name]))

        for state_variable in self.statevariable_writers:
            if state_variable in self.statevariable_readers:
                for pair in itertools.product(self.statevariable_writers[state_variable], self.statevariable_readers[state_variable]):
                    left, right = pair
                    if left == right:
                        continue
                    else:
                        self.atomic_locks[left.full_name] = list(set(self.atomic_locks.get(
                            left.full_name, list())).union([right.full_name]))

    def get_temporal_lock_policies(self):
        # TODO: instrument reader-writer locks into normal smart contract partition where a method could be split into multiple smaller ones
        # How to place reader-writer locks is a bit complicated?
        # Rules:
        # 1. For each method, acquire reader-writer locks first for state variables read or write
        # 2. For each method, release reader-writer locks at the program exit.
        # We may not need to enforce reader-writer locks for every method, this will incur a lot of overhead.
        # We should probably insert reader-writer locks for only the functions that may have temporal relations/transaction order dependency with the critical functions containing sensitive operations that we want to partition
        # Should we consider propagation or transitive closure of these temporal relations?
        # For example, B depends on C (one critical function), but A depends on B
        #  C, B, A
        # Sequential equivalence relation

        self.initialize_readers_writers()
        self.create_tempory_lock_policy()
        return self.atomic_locks
