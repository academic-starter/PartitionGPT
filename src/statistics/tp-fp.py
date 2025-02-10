import os
import glob
import json
import pandas as pd 
import numpy as np 

work_dir = "./advanced-gpt4o_mini"
partition_files = glob.glob(os.path.join(work_dir, "*.partition.json"))

distance_weight = 0.55995614
global_ratio_weight = 0.17736604
local_ratio_weight = 0.26267782

data = dict()
contracts = []
func_counts = []
partition_counts =[]
non_partition_func_counts = []
top_1s = []
top_2s = []
top_3s = []
top_4s = []
top_5s = []
for partition_file in partition_files:
    all_partitions = json.load(open(partition_file))
    contract_name = os.path.basename(partition_file).split(".")[0].strip()
    func_count = len(all_partitions)
    partition_count = np.sum([len(func_partitions["partitions"]) for func_partitions in all_partitions])
    non_partition_func_count = len(list(filter(lambda func_partitions: len(func_partitions["partitions"])==0, all_partitions)))
    Top_ks = dict()
    for func_partitions in all_partitions:
        results = []
        func_name = func_partitions["target_func_name"]
        partitions = func_partitions["partitions"]
        for index in partitions:
            partition = partitions[index]
            if "global_ratio" in partition:
                predict_score = distance_weight * partition["normalized_distance"] + \
                    global_ratio_weight * partition["global_ratio"] + local_ratio_weight * partition["local_ratio"] 
                groundtruth_similarity = partition["groundtruth_similarity"]
                results.append((predict_score, groundtruth_similarity, index, partition))

        ranking = sorted(results, key=lambda x: x[0], reverse=True)

        facts = sorted(results, key=lambda x: x[1], reverse=True)

        MAX = 5
        for k in range(MAX):
            if k+1 not in Top_ks:
                Top_ks[k+1] = []
            top_k = ranking[:k+1]
            verification_result = []
            for i, item in enumerate(top_k):
                partition = item[-1]
                try: 
                    prover_result = partition["prover_result"]
                    status = prover_result["status"]
                    verification_result.append(1 if status else 0)
                except:
                    # print(partition)
                    # exit(0)
                    continue
            if len(verification_result) > 0:
                Top_ks[k+1].append(np.sum(verification_result))
    top_1 = np.sum(Top_ks[1])
    top_2 = np.sum(Top_ks[2])
    top_3 = np.sum(Top_ks[3])
    top_4 = np.sum(Top_ks[4])
    top_5 = np.sum(Top_ks[5])
    
    contracts.append(contract_name)
    func_counts.append(func_count)
    partition_counts.append(partition_count)
    non_partition_func_counts.append(non_partition_func_count)
    top_1s.append(top_1)
    top_2s.append(top_2)
    top_3s.append(top_3)
    top_4s.append(top_4)
    top_5s.append(top_5)

df = pd.DataFrame.from_dict(dict(contracts=contracts, func_counts=func_counts, partition_counts=partition_counts, non_partition_func_counts =non_partition_func_counts, Top_1=top_1s, Top_2=top_2s, Top_3=top_3s, Top_4=top_4s, Top_5=top_5s))
print(df)
df.to_csv("./RQ1-TP-Experiment.csv", index=False)


work_dir = "./advanced-gpt4o_mini"
partition_files = glob.glob(os.path.join(work_dir, "*.partition.json"))

distance_weight = 0.59421478
global_ratio_weight = 0.19162208
local_ratio_weight = 0.21416315

data = dict()
contracts = []
func_counts = []
partition_counts =[]
non_partition_func_counts = []
top_1s = []
top_2s = []
top_3s = []
top_4s = []
top_5s = []
for partition_file in partition_files:
    all_partitions = json.load(open(partition_file))
    contract_name = os.path.basename(partition_file).split(".")[0].strip()
    func_count = len(all_partitions)
    partition_count = np.sum([len(func_partitions["partitions"]) for func_partitions in all_partitions])
    non_partition_func_count = len(list(filter(lambda func_partitions: len(func_partitions["partitions"])==0, all_partitions)))
    Top_ks = dict()
    for func_partitions in all_partitions:
        results = []
        func_name = func_partitions["target_func_name"]
        partitions = func_partitions["partitions"]
        for index in partitions:
            partition = partitions[index]
            if "global_ratio" in partition:
                predict_score = distance_weight * partition["normalized_distance"] + \
                    global_ratio_weight * partition["global_ratio"] + local_ratio_weight * partition["local_ratio"] 
                groundtruth_similarity = partition["groundtruth_similarity"]
                results.append((predict_score, groundtruth_similarity, index, partition))

        ranking = sorted(results, key=lambda x: x[0], reverse=True)

        facts = sorted(results, key=lambda x: x[1], reverse=True)

        MAX = 5
        for k in range(MAX):
            if k+1 not in Top_ks:
                Top_ks[k+1] = []
            top_k = ranking[:k+1]
            verification_result = []
            for i, item in enumerate(top_k):
                partition = item[-1]
                try: 
                    prover_result = partition["prover_result"]
                    status = prover_result["status"]
                    verification_result.append(1 if status else 0)
                except:
                    # print(partition)
                    # exit(0)
                    continue
            if len(verification_result) > 0:
                Top_ks[k+1].append(1 if np.sum(verification_result)>0 else 0)
    top_1 = np.sum(Top_ks[1])
    top_2 = np.sum(Top_ks[2])
    top_3 = np.sum(Top_ks[3])
    top_4 = np.sum(Top_ks[4])
    top_5 = np.sum(Top_ks[5])
    
    contracts.append(contract_name)
    func_counts.append(func_count)
    partition_counts.append(partition_count)
    non_partition_func_counts.append(non_partition_func_count)
    top_1s.append(top_1)
    top_2s.append(top_2)
    top_3s.append(top_3)
    top_4s.append(top_4)
    top_5s.append(top_5)

df = pd.DataFrame.from_dict(dict(contracts=contracts, func_counts=func_counts, partition_counts=partition_counts, non_partition_func_counts =non_partition_func_counts, Top_1=top_1s, Top_2=top_2s, Top_3=top_3s, Top_4=top_4s, Top_5=top_5s))
print(df)
df.to_csv("./RQ1-HIT-Experiment.csv", index=False)


import os
import glob
import json
import pandas as pd 
import numpy as np 

work_dir = "./advanced-gpt4o_mini"
partition_files = glob.glob(os.path.join(work_dir, "*.partition.json"))

distance_weight = 0.59421478
global_ratio_weight = 0.19162208
local_ratio_weight = 0.21416315

data = dict()
contracts = []
func_counts = []
partition_counts =[]
non_partition_func_counts = []
top_1s = []
top_2s = []
top_3s = []
top_4s = []
top_5s = []
for partition_file in partition_files:
    all_partitions = json.load(open(partition_file))
    contract_name = os.path.basename(partition_file).split(".")[0].strip()
    func_count = len(all_partitions)
    partition_count = np.sum([len(func_partitions["partitions"]) for func_partitions in all_partitions])
    non_partition_func_count = len(list(filter(lambda func_partitions: len(func_partitions["partitions"])==0, all_partitions)))
    Top_ks = dict()
    for func_partitions in all_partitions:
        results = []
        func_name = func_partitions["target_func_name"]
        partitions = func_partitions["partitions"]
        for index in partitions:
            partition = partitions[index]
            if "global_ratio" in partition:
                predict_score = distance_weight * partition["normalized_distance"] + \
                    global_ratio_weight * partition["global_ratio"] + local_ratio_weight * partition["local_ratio"] 
                groundtruth_similarity = partition["groundtruth_similarity"]
                results.append((predict_score, groundtruth_similarity, index, partition))

        ranking = sorted(results, key=lambda x: x[0], reverse=True)

        facts = sorted(results, key=lambda x: x[1], reverse=True)

        MAX = 5
        for k in range(MAX):
            if k+1 not in Top_ks:
                Top_ks[k+1] = []
            top_k = ranking[:k+1]
            verification_result = []
            for i, item in enumerate(top_k):
                partition = item[-1]
                try:
                    prover_result = partition["prover_result"]
                    status = prover_result["status"]
                    verification_result.append(0 if status else 1)
                except:
                    continue
            if len(verification_result) > 0:
                Top_ks[k+1].append(np.sum(verification_result))
    top_1 = np.sum(Top_ks[1])
    top_2 = np.sum(Top_ks[2])
    top_3 = np.sum(Top_ks[3])
    top_4 = np.sum(Top_ks[4])
    top_5 = np.sum(Top_ks[5])
    
    contracts.append(contract_name)
    func_counts.append(func_count)
    partition_counts.append(partition_count)
    non_partition_func_counts.append(non_partition_func_count)
    top_1s.append(top_1)
    top_2s.append(top_2)
    top_3s.append(top_3)
    top_4s.append(top_4)
    top_5s.append(top_5)

df = pd.DataFrame.from_dict(dict(contracts=contracts, func_counts=func_counts, partition_counts=partition_counts, non_partition_func_counts =non_partition_func_counts, Top_1=top_1s, Top_2=top_2s, Top_3=top_3s, Top_4=top_4s, Top_5=top_5s))
print(df)
df.to_csv("./RQ1-FP-Experiment.csv", index=False)





import os
import glob
import json
import pandas as pd 
import numpy as np 
from src.framework.compile import Compilation, ContractWrapper
from src.extractor.sourcecode_catcher import SourceCodeCatcher
def create_contract_wrapper(file_path, target_contract_name, solc_version="0.8.25", solc_remaps=[]) -> ContractWrapper:
    instance = Compilation(contract_file=file_path,
                           solc_remaps=solc_remaps, solc_version=solc_version)

    wrapper = ContractWrapper(
        target_contract_name=target_contract_name, compilation=instance)
    return wrapper

def get_priv_ratio(output_code, all_extern_deps_code, original_code, func_name, target_contract_name):
    complete_code = "{0}\n{1}".format(all_extern_deps_code, output_code)
    tmp_file = ".tmp.sol"
    open(tmp_file, "w").write(complete_code)
    wrapper = create_contract_wrapper(file_path= tmp_file, target_contract_name=target_contract_name)
    privFunc = wrapper.get_functions_from_name(func_name=func_name+"_priv")[0]
    all_codes_of_priv = SourceCodeCatcher.get_function_full_context(privFunc, wrapper)
    
    complete_code = "{0}\n{1}".format(all_extern_deps_code, original_code)
    tmp_file = ".tmp.sol"
    open(tmp_file, "w").write(complete_code)
    wrapper = create_contract_wrapper(file_path= tmp_file, target_contract_name=target_contract_name)
    origFunc = wrapper.get_functions_from_name(func_name=func_name)[0]
    all_codes_of_orig = SourceCodeCatcher.get_function_full_context(origFunc, wrapper)
    
    ratio = len(("\n".join(all_codes_of_priv)).split("\n"))/len(("\n".join(all_codes_of_orig)).split("\n"))
    return ratio

work_dir = "./advanced-gpt4o_mini"
partition_files = glob.glob(os.path.join(work_dir, "*.partition.json"))

distance_weight = 0.59421478
global_ratio_weight = 0.19162208
local_ratio_weight = 0.21416315

data = dict()
contracts = []
func_counts = []
partition_counts =[]
non_partition_func_counts = []
top_1s = []
top_2s = []
top_3s = []
top_4s = []
top_5s = []
for partition_file in partition_files:
    all_partitions = json.load(open(partition_file))
    contract_name = os.path.basename(partition_file).split(".")[0].strip()
    func_count = len(all_partitions)
    partition_count = np.sum([len(func_partitions["partitions"]) for func_partitions in all_partitions])
    non_partition_func_count = len(list(filter(lambda func_partitions: len(func_partitions["partitions"])==0, all_partitions)))
    Top_ks = dict()
    for func_partitions in all_partitions:
        results = []
        func_name = func_partitions["target_func_name"]
        partitions = func_partitions["partitions"]
        original_code = func_partitions["original_code"]
        all_extern_deps_code = func_partitions["all_extern_deps_code"]
        for index in partitions:
            partition = partitions[index]
            if "global_ratio" in partition:
                predict_score = distance_weight * partition["normalized_distance"] + \
                    global_ratio_weight * partition["global_ratio"] + local_ratio_weight * partition["local_ratio"] 
                groundtruth_similarity = partition["groundtruth_similarity"]
                results.append((predict_score, groundtruth_similarity, index, contract_name, func_name, original_code, all_extern_deps_code, partition))

        ranking = sorted(results, key=lambda x: x[0], reverse=True)

        facts = sorted(results, key=lambda x: x[1], reverse=True)

        MAX = 5
        for k in range(MAX):
            if k+1 not in Top_ks:
                Top_ks[k+1] = []
            top_k = ranking[:k+1]
            priv_ratios = []
            for i, item in enumerate(top_k):
                partition = item[-1]
                output_code = partition["output_code"]
                all_extern_deps_code = item[-2]
                original_code = item[-3]
                func_name = item[-4]
                contract_name = item[-5]
                try:
                    ratio = get_priv_ratio(output_code=output_code, all_extern_deps_code=all_extern_deps_code, original_code=original_code, func_name=func_name, target_contract_name=contract_name)
                    # print("priv_ratio:", ratio)
                    priv_ratios.append(round(ratio, 4))
                except:
                    import traceback 
                    # traceback.print_exc()
                    pass 
            
            if len(priv_ratios) > 0:
                Top_ks[k+1].append(np.average(priv_ratios))
    top_1 = np.average(Top_ks[1])
    top_2 = np.average(Top_ks[2])
    top_3 = np.average(Top_ks[3])
    top_4 = np.average(Top_ks[4])
    top_5 = np.average(Top_ks[5])
    
    contracts.append(contract_name)
    func_counts.append(func_count)
    partition_counts.append(partition_count)
    non_partition_func_counts.append(non_partition_func_count)
    top_1s.append(top_1)
    top_2s.append(top_2)
    top_3s.append(top_3)
    top_4s.append(top_4)
    top_5s.append(top_5)

df = pd.DataFrame.from_dict(dict(contracts=contracts, func_counts=func_counts, partition_counts=partition_counts, non_partition_func_counts =non_partition_func_counts, Top_1=top_1s, Top_2=top_2s, Top_3=top_3s, Top_4=top_4s, Top_5=top_5s))
print(df)
df.to_csv("./RQ1-Priv-Experiment.csv", index=False)

