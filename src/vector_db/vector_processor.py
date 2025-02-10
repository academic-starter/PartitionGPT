import itertools
import os
import json
import pickle
import openai
import numpy as np
from tqdm import tqdm

from pathlib import Path
import src.vector_db.config as config


# 辅助函数，将可迭代对象分割成多个块
def chunks(iterable, batch_size=100):
    it = iter(iterable)
    chunk = list(itertools.islice(it, batch_size))
    while chunk:
        yield chunk
        chunk = list(itertools.islice(it, batch_size))

# Read and create an exclusion set from secondcategory_filter.csv


def generate_update_embeddings(benchmarks: dict, excluded_testing_set, existing_embeddings=None):
    new_embeddings = {}
    new_metadata_list = []
    for item in tqdm(set(benchmarks.keys()).difference(excluded_testing_set), desc="Vectorizing Partitioning", total=len(set(benchmarks.keys()).difference(excluded_testing_set)), ncols=100):
        row_id = item
        function_partitions = benchmarks[row_id]
        for row_id, function_partition in enumerate(function_partitions):
            row_id = item + "-" + str(row_id)
            if existing_embeddings and row_id in existing_embeddings:
                continue  # 如果已存在嵌入，则跳过
            try:
                openai.api_key = config.OPENAI_API_KEY
                function_code = "\n".join(function_partition["original"])
                response = openai.Embedding.create(
                    model=config.PRETRAIN_MODEL_OPENAI, input=function_code)
                embedding = response['data'][0]['embedding']
                new_embeddings[row_id] = embedding
                # 构建并添加元数据
                metadata = {
                    "Contract": item,
                    "Partition": "\n".join(function_partition["partition"]),
                    "Original": function_code
                }
                new_metadata_list.append(metadata)
            except Exception as e:
                print("Error:", e)
                new_embeddings[row_id] = np.zeros(1536).tolist()
                # 处理错误情况的元数据
                # ...
    return new_embeddings, new_metadata_list


# 保存嵌入和元数据的函数
def save_embeddings(embeddings, metadata_list, filepath):
    with open(filepath, 'wb') as f:
        pickle.dump((embeddings, metadata_list), f)


# # 从新的CSV进行增量更新的函数
# def update_embeddings_from_new_csv(new_csv_path, existing_pkl_path):
#     new_df = pd.read_csv(new_csv_path)

#     # 如果存在，则加载现有嵌入
#     if os.path.exists(existing_pkl_path):
#         with open(existing_pkl_path, 'rb') as f:
#             existing_embeddings, existing_metadata = pickle.load(f)
#     else:
#         existing_embeddings = None

#     # 生成新嵌入并更新现有嵌入
#     new_embeddings, new_metadata_list = generate_update_embeddings(
#         new_df, existing_embeddings)

#     # 合并现有和新嵌入
#     if existing_embeddings:
#         combined_embeddings = {**existing_embeddings, **new_embeddings}
#     else:
#         combined_embeddings = new_embeddings

#     # 合并现有和新元数据
#     combined_metadata_list = existing_metadata + \
#         new_metadata_list if existing_metadata else new_metadata_list

#     # 保存合并后的嵌入
#     save_embeddings(combined_embeddings,
#                     combined_metadata_list, existing_pkl_path)
#     print("更新嵌入，并保存到", existing_pkl_path)


# 使用示例
json_path = 'src/partition_benchmark.json'  # benchmark json file
pkl_path = './src/vector_db/basic_data/embeddings.pkl'  # .pkl文件的路径

excluded_testing_set = [
    "BlindAuction",
    "Comp",
    "ConfidentialIdentityRegistry",
    "EncryptedERC20",
    "GovernorZama",
    "NFTExample"
]

# If you need to completely regenerate the embedding file
benchmarks = json.load(open(json_path))
embeddings, metadata_list = generate_update_embeddings(
    benchmarks, excluded_testing_set)
save_embeddings(embeddings, metadata_list, pkl_path)
# 如果您有新数据需要增量添加
# update_embeddings_from_new_csv(new_csv_path, pkl_path)
