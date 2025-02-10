import os
import glob
import json
import pandas as pd 
import numpy as np 

work_dir = "./advanced"
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
                results.append((predict_score, groundtruth_similarity))

        ranking = sorted(results, key=lambda x: x[0], reverse=True)

        facts = sorted(results, key=lambda x: x[1], reverse=True)

        MAX = 5
        for k in range(MAX):
            if k+1 not in Top_ks:
                Top_ks[k+1] = []
            top_k = ranking[:k+1]
            act_score_sum = []
            for i, item in enumerate(top_k):
                print("Rank(predicated):{0} Rank(actual): {1}, Score(predicated):{2}, Score(actual): {3} ".format(
                    i+1, facts.index(item)+1, item[0], item[1]))
                act_score_sum.append(item[1])
            if len(act_score_sum) == k+1:
                Top_ks[k+1].append(np.sum(act_score_sum)/len(act_score_sum))
    top_1 = round(100*np.sum(Top_ks[1])/len(Top_ks[1]),2)
    top_2 = round(100*np.sum(Top_ks[2])/len(Top_ks[2]),2)
    top_3 = round(100*np.sum(Top_ks[3])/len(Top_ks[3]),2)
    top_4 = round(100*np.sum(Top_ks[4])/len(Top_ks[4]),2)
    top_5 = round(100*np.sum(Top_ks[5])/len(Top_ks[5]),2)
    
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
df.to_csv("./RQ1-Experiment.csv", index=False)

