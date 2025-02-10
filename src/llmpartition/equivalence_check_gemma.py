import os
import glob
import json
import pandas as pd 
import numpy as np 
from tqdm import tqdm
import subprocess

def eq_check(contract_name, func_name, index, all_extern_deps_code, code):
    out_dir = "./eq_checks-gemma2_27b"
    if not os.path.exists(out_dir):
        os.mkdir(out_dir)
    full_code = "{0}\n{1}".format(all_extern_deps_code, code)
    sol_file = os.path.join(out_dir, "{0}-{1}-{2}.sol".format(contract_name, func_name, index))
    if not os.path.exists(sol_file):
        open(sol_file, "w").write(full_code)
    cmd = ["./solidity/build/solver/solver", "eq_check", "-max-exec-time", 600, "-files", sol_file, "-m", contract_name, "-functions", func_name, func_name+"_new"]
    result = subprocess.run(
        cmd,
        stdout = subprocess.PIPE,
        stderr = subprocess.PIPE,
        universal_newlines = True # Python >= 3.7 also accepts "text=True"
    )
    
    # print("stdout:", result.stdout is not None, result.stdout)
    # print("stderr:", result.stderr is not None, result.stderr)
    # if result.stderr is not None:
        
    #     fails = list(filter(lambda line: line.find("equivalance check failed")!=-1, result.stderr.split("\n")))
    #     if len(fails) == 0:
    #         return False, ["Unknown prover issues"] # -1 indicating Unknown scenarios. Probably prover fails due to internal design issue.
    #     else:
    #         return False, fails
    if result.stdout is not None:
        fails = list(filter(lambda line:line.find("equivalence check failed")!=-1, result.stdout.split("\n")))
        if len(fails) == 0:
            pass_eq_checks = list(filter(lambda line:line.find("Pass equivalence checking")!=-1, result.stdout.split("\n")))
            if len(pass_eq_checks) > 0:
                return True, "Pass equivalence checking"
            else:
                return False, result.stderr
        else:
            fails =  list(filter(lambda line: line.find("Revert condition equivalence check failed")==-1, fails))
            if len(fails) == 0:
                return True, "Pass equivalence checking"
            else:
                return False, fails + [result.stderr]

work_dir = "./advanced-gemma2_27b"
partition_files = glob.glob(os.path.join(work_dir, "*.partition.json"))

for partition_file in partition_files:
    all_partitions = json.load(open(partition_file))
    contract_name = os.path.basename(partition_file).split(".")[0].strip()
    func_count = len(all_partitions)
    partition_count = np.sum([len(func_partitions["partitions"]) for func_partitions in all_partitions])
    non_partition_func_count = len(list(filter(lambda func_partitions: len(func_partitions["partitions"])==0, all_partitions)))
    Top_ks = dict()
    print(contract_name)
    if contract_name == "AuctionInstance":
        continue
    statuses = []
    reasons = []
    for func_partitions in tqdm(all_partitions):
        results = []
        func_name = func_partitions["target_func_name"]
        partitions = func_partitions["partitions"]
        original_code = func_partitions["original_code"]
        all_extern_deps_code = func_partitions["all_extern_deps_code"]
        for index in partitions:
            partition = partitions[index]
            code = partition["merged_code"] 
            status, reason = eq_check(contract_name=contract_name, func_name=func_name, index = index, all_extern_deps_code=all_extern_deps_code, code = code)
            partition["prover_result"] = dict(status=status, reason=reason)
            # print(status, reason)
            # exit(0)
            statuses.append(status)
            reasons.append(reason)
    pass_cnt = np.count_nonzero(list(map(lambda x: 1 if x else 0, statuses)))
    print("Pass rate:{0}".format(pass_cnt/len(statuses)))
    
    json.dump(all_partitions, open(partition_file, "w"), indent=4)  