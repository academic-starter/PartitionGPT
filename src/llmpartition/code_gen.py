import os
import traceback
import subprocess
import json
import openai
from ollama import Client

import editdistance
from typing import Set, Tuple, List
from sklearn.metrics.pairwise import cosine_similarity
from slither.core.cfg.node import NodeType
from slither.core.declarations.function import Function, FunctionType, FunctionLanguage
from src.framework.compile import Compilation, ContractWrapper
from src.extractor.sourcecode_catcher import SourceCodeCatcher

from src.framework.taint_tracking import TaintTrack
from src.framework.dependency import APINode, ProgramDependency
from src.vector_db import config
from .prompt import format_template, transformation_template, transformation_example, transformation_example2, grammar_fix_template, instrumentation_template, verification_question_template, secure_fix_question_template
from ..vector_db.cosine_similarity_getter import EmbeddingAnalyzer
from . import model_config as model_config

openai.api_key = config.OPENAI_API_KEY
client = Client(
  host='http://localhost:11434',
  headers={'x-some-header': 'some-value'}
)

# LIMIT_COUNT =  10
LIMIT_COUNT = 10
CANDIDATE_LIMIT = 10

def get_llm_result(prompt, example_prompts):
    # few-shot learning
    if model_config.LLM == "gpt-4o-mini":
        chat_completion = openai.ChatCompletion.create(
            messages=[
                {
                    "role": "user",
                    "content": example,
                } for example in example_prompts] + [
                {
                    "role": "user",
                    "content": prompt,
                }
            ],
            model= model_config.LLM,
        )

        response = chat_completion.choices[0].message
        refusal = response.refusal
        content = response.content
        # print(content)
        return content
    else:
        response = client.chat(messages=[
                {
                    "role": "user",
                    "content": example,
                } for example in example_prompts] + [
                {
                    "role": "user",
                    "content": prompt,
                }
            ],
            model= model_config.LLM,
            )
        content = response.message.content
        return content

def create_contract_wrapper(file_path, target_contract_name, solc_version, solc_remaps) -> ContractWrapper:
    instance = Compilation(contract_file=file_path,
                           solc_remaps=solc_remaps, solc_version=solc_version)

    wrapper = ContractWrapper(
        target_contract_name=target_contract_name, compilation=instance)
    return wrapper


def compute_normalized_ratio_of_privilege_function(file_path, target_contract_name, solc_version, solc_remaps, target_func_name):

    wrapper = create_contract_wrapper(
        file_path, target_contract_name, solc_version, solc_remaps)
    try:
        func = wrapper.get_functions_from_name(target_func_name)[0]
        func_code = SourceCodeCatcher.get_function_full_context(func, wrapper)
        priv_sub_funcs = []
        for internal_call in func.internal_calls:
            if isinstance(internal_call, Function):
                if internal_call.name.endswith("_priv"):
                    # TODO: currently we assume that LLM will strictly follow my instruction to generate xxx_priv function
                    priv_sub_funcs.append(internal_call)
                    break
                else:
                    continue
        if len(priv_sub_funcs) == 1:
            priv_sub_func = priv_sub_funcs[0]
            priv_func_code = SourceCodeCatcher.get_function_full_context(
                priv_sub_func, wrapper)
            ratio = len(priv_func_code) / len(func_code)
            return ratio
        else:
            print("Do not find a internal function ending with `_priv`")
            return None
    except:
        return None


def get_priv_ratio(transformed_code, all_extern_deps_code, sensitive_variables, target_contract_name, target_func_name):
    complete_code = "{0}\n{1}".format(all_extern_deps_code, transformed_code)
    tmp_file = ".{0}.tmp.sol".format(model_config.LLM)
    open(tmp_file, "w").write(complete_code)

    pdg, tainter = taint_analysis(file_path=tmp_file, target_contract_name=target_contract_name,
                                  sensitive_vars=sensitive_variables, solc_version="0.8.25", solc_remaps=[])
    target_contract_funcs = pdg.contract.get_functions_from_name(
        target_func_name)
    assert len(target_contract_funcs) > 0, "did not find function {0}".format(
        target_func_name)
    target_contract_func = target_contract_funcs[0]
    # sink_or_sources: Set = tainter.get_taint_sink_source_node_for_func(
    #     target_contract_func)

    global_ratio = compute_normalized_ratio_of_privilege_function(file_path=tmp_file, target_contract_name=target_contract_name,
                                                                  solc_version="0.8.25", solc_remaps=[], target_func_name=target_func_name)
    # size_priv_nodes = len(set(map(
    #     lambda x: x.node, tainter.get_taint_sinks().union(tainter.get_taint_sources()))))
    for internal_call in target_contract_func.internal_calls:
        if isinstance(internal_call, Function) and internal_call.name.endswith("_priv"):
            size_priv_nodes = len(set(map(
                lambda x: x.node, tainter.get_taint_sink_source_node_for_func(
                    internal_call))))
            all_funcs: List[Function] = SourceCodeCatcher.get_function_full_context_raw(
                internal_call, pdg.contract)

            size_func_nodes = 0
            for func in all_funcs:
                size_func_nodes += len(list(filter(lambda node: node.type not in [NodeType.ENTRYPOINT,NodeType.OTHER_ENTRYPOINT, NodeType.ENDLOOP, NodeType.ENDIF] , func.nodes)))

            ratio = size_priv_nodes / size_func_nodes
            if ratio > 1:
                # TODO: Error if ratio is greater than 1
                return global_ratio, 1
            else:
                return global_ratio, ratio

    assert False, "Invalid partition"


def taint_analysis(file_path, target_contract_name, sensitive_vars, solc_version, solc_remaps) -> Tuple[ProgramDependency, TaintTrack]:
    # instance = Compilation(contract_file=file_path,
    #                        solc_remaps=solc_remaps, solc_version=solc_version)
    # wrapper = ContractWrapper(
    #     target_contract_name=target_contract_name, compilation=instance)
    wrapper = create_contract_wrapper(
        file_path, target_contract_name, solc_version, solc_remaps)
    pdg = ProgramDependency(contract=wrapper)
    pdg.generate_dependencies()

    match_name_sensitive_vars = set()
    for func in wrapper.contract.functions:
        for variable in func.variables_read_or_written:
            if any([variable.name == item.name for item in sensitive_vars]):
                match_name_sensitive_vars.add(variable)

    tainter = TaintTrack(pdg, sensitive_var_names=match_name_sensitive_vars)
    tainter.compute()
    return pdg, tainter




def get_groundtruth_partition(target_contract_name, target_func_name):
    partitions = json.load(open("src/partition_benchmark.json"))
    for item in partitions:
        contract_partitons = partitions[item]
        for contract_partition in contract_partitons:
            if contract_partition["target_contract_name"] == target_contract_name and contract_partition["target_func_name"] == target_func_name:
                return contract_partition["partition"]
    return None


def check_is_secure_partition(transformed_code, all_extern_deps_code, sensitive_variables, target_contract_name, target_func_name):
    complete_code = "{0}\n{1}".format(transformed_code, all_extern_deps_code)
    tmp_file = ".{0}.tmp.sol".format(model_config.LLM)
    open(tmp_file, "w").write(complete_code)
    pdg, tainter = taint_analysis(file_path=tmp_file, target_contract_name=target_contract_name,
                                  sensitive_vars=sensitive_variables, solc_version="0.8.25", solc_remaps=[])
    target_contract_funcs = pdg.contract.get_functions_from_name(
        target_func_name)
    assert len(target_contract_funcs) > 0, "did not find function {0}".format(
        target_func_name)
    target_contract_func = target_contract_funcs[0]

    all_priv_nodes = [node.source_mapping.content for node in set(map(
                    lambda x: x.node, tainter.get_taint_sink_source_node_for_func(target_contract_func)))]
    for internal_call in target_contract_func.internal_calls:
        if isinstance(internal_call, Function) and internal_call.name.endswith("_priv"):
            # print("\n".join(all_priv_nodes))
            # print("--------------------------------")
            included_priv_nodes = [node.source_mapping.content for node in set(map(
                    lambda x: x.node, tainter.get_taint_sink_source_node_for_func(
                        internal_call)))]
            # print("\n".join(included_priv_nodes))
            unexpected_priv_nodes = set(
                    all_priv_nodes).difference(included_priv_nodes)
            unexpected_priv_nodes = list(
                    filter(lambda x: x.find("_priv") == -1 and x.find("_callback") == -1 and x.find("return") == -1, unexpected_priv_nodes))
            if len(unexpected_priv_nodes)>0:
                return False, "Insecure! the function body of {0} has privilege operations: {1}".format(target_func_name, "\n".join(unexpected_priv_nodes))
            else:
                return True, ""

    return False, "Incorrect! the function body of {0} does not have a privileged sub function in the form of XXX_priv".format(target_func_name)


def transform(original_code, all_extern_deps_code, priv_nodes, priv_slice, normal_slice, sensitive_variables, target_contract_name, target_func_name):
    print("\n>>Contract:{0}\n>>Function:{1}".format(target_contract_name, target_func_name))
    all_partitions: dict = dict()

    analyzer = EmbeddingAnalyzer()

    result = get_llm_result(format_template.format(
        original_contract=original_code), [])
    original_code = result.replace(
        "```solidity", "").replace("```", "")

    if all_extern_deps_code:
        # print("External code: " + all_extern_deps_code)
        pass
    else:
        all_extern_deps_code = ""

    def compile_multiple_tries(output_code):
        success, error_feeback = compile(output_code, all_extern_deps_code)
        fixCount = 0
        fixCountLimit = LIMIT_COUNT
        while not success and fixCount < fixCountLimit:
            grammar_fix_prompt = grammar_fix_template.format(
                input_contract=output_code, error_msg=error_feeback)
            result = get_llm_result(grammar_fix_prompt, [])
            output_code = result.replace(
                "```solidity", "").replace("```", "")
            success, error_feeback = compile(output_code, all_extern_deps_code)
            fixCount += 1
        if fixCount > 0 and fixCount < fixCountLimit:
            print("Take {0} fix!".format(fixCount))
            return output_code
        elif fixCount == fixCountLimit:
            print("Cannot fix! exceeding {0} times".format(fixCount))
            raise Exception("Cannot fix! exceeding {0} times".format(fixCount))
        else:
            return output_code

    def multi_steps(gen_round):
        transformation_promt = transformation_template.format(
            original_function_code="\n".join(original_code) if isinstance(original_code, list) else original_code, privilege_code=priv_nodes, slice_priv=priv_slice, slice_normal=normal_slice)

        # print("\n\n".join(example_prompts))

        print(transformation_promt)

        result = get_llm_result(transformation_promt, [transformation_example, transformation_example2])

        output_code = result.replace(
            "```solidity", "").replace("```", "")

        try:
            output_code = compile_multiple_tries(output_code)
            isSecure, failure_reason = check_is_secure_partition(transformed_code=output_code, all_extern_deps_code=all_extern_deps_code,
                                                                 sensitive_variables=sensitive_variables, target_contract_name=target_contract_name, target_func_name=target_func_name)

            repairCount = 0
            repairCountLimit = LIMIT_COUNT
            while not isSecure and repairCount < repairCountLimit:

                secure_fix_question = secure_fix_question_template.format(privilege_code=priv_nodes,
                                                                          original_contract=original_code, transformed_contract=output_code, explanation=failure_reason,
                                                                          slice_priv=priv_slice, slice_normal=normal_slice)
                print("Repair unsecure partition")
                print(secure_fix_question)
                result = get_llm_result(secure_fix_question, [
                    transformation_example, transformation_example2])
                output_code = result.replace(
                    "```solidity", "").replace("```", "")
                output_code = compile_multiple_tries(output_code)

                isSecure, failure_reason = check_is_secure_partition(transformed_code=output_code, all_extern_deps_code=all_extern_deps_code,
                                                                     sensitive_variables=sensitive_variables, target_contract_name=target_contract_name, target_func_name=target_func_name)
                repairCount += 1

            if repairCount == repairCountLimit:
                print("Cannot repair! exceeding {0} times".format(repairCount))
                raise Exception("Cannot repair! exceeding {0} times".format(repairCount))
            else:
                if repairCount > 0:
                    print("Take {0} repair!".format(repairCount))
                distance = editdistance.eval(original_code, output_code)
                normalized_distance = distance / \
                    max(len(original_code), len(output_code))
                print("Edit distance(normalized) {0}".format(
                    normalized_distance))

                global_ratio, ratio = get_priv_ratio(transformed_code=output_code, all_extern_deps_code=all_extern_deps_code, sensitive_variables=sensitive_variables,
                                                     target_contract_name=target_contract_name, target_func_name=target_func_name)
                print(
                    "Ratio of privilege codebase size: global {0} local {1}".format(global_ratio, ratio))
                print("Candidate#{0}:".format(gen_round))
                print(output_code)
                return output_code, normalized_distance, global_ratio, ratio, repairCount
        except Exception as e:
            traceback.print_exc()
            raise e

    candidateCountLimit = CANDIDATE_LIMIT
    candidateCount = 0
    groundtruth_transformed_code = get_groundtruth_partition(
        target_contract_name=target_contract_name, target_func_name=target_func_name)
    while candidateCount < candidateCountLimit:
        try:
            print("--------------------------------------------")
            print("{0}th Attempt to generate partition candidate...".format(candidateCount))
            output_code, normalized_distance, global_ratio, local_ratio, repair_count = multi_steps(
                gen_round=candidateCount+1)
            candidateCount += 1

            if output_code is not None and groundtruth_transformed_code is not None:
                input_embedding_result = analyzer.convert_to_embedding(
                    output_code)
                input_embedding_groundtruth = analyzer.convert_to_embedding(
                    groundtruth_transformed_code)
                similarities = cosine_similarity([input_embedding_result], [
                    input_embedding_groundtruth])
                similarity = similarities[0]
                # print("Similarity Score: " + str(similarity))
                # print("Ground truth: " + groundtruth_transformed_code)

                print("\n********************************")
                print("Summary(Edit distance, Size of privilege (global), Size of privilege (local),Similarity score):({0}, {1}, {2},  {3})".format(
                    normalized_distance, global_ratio, local_ratio, similarity[0]))
                print("********************************\n")
                all_partitions[candidateCount] = dict(
                    output_code=output_code, normalized_distance=normalized_distance, global_ratio=global_ratio, local_ratio=local_ratio, groundtruth_similarity=float(similarity[0]), repair_count = repair_count)
        except:
            print("Error: {0}th Attempt failed".format(candidateCount))
            candidateCount += 1
    return dict(target_contract_name=target_contract_name, target_func_name=target_func_name, original_code=original_code, all_extern_deps_code=all_extern_deps_code, groundtruth_transformed_code=groundtruth_transformed_code, partitions=all_partitions)


def verify(original_code, output_code):
    verification_question = verification_question_template.format(
        original_contract=original_code, transformed_contract=output_code)
    result = get_llm_result(verification_question, [])
    if result == "Yes":
        return True, None
    else:
        return False, result


def compile(transformed_function_code, all_extern_deps_code):
    complete_contract_code = "{0} \n {1}".format(
        transformed_function_code, all_extern_deps_code)
    tmp_file = ".{0}.tmp.sol".format(model_config.LLM)
    open(tmp_file, "w").write(complete_contract_code)
    # Example: Running a shell command and capturing its output
    result = subprocess.run(
        ["solc", tmp_file],  # Command as a list
        capture_output=True,  # Captures both stdout and stderr
        text=True        # Returns the output as a string instead of bytes
    )

    # Access the output and error
    # print("Output:\n", result.stdout)
    # print("Error:\n", result.stderr)
    if result.stderr.find("Error:") != -1:
        print("Compilation Error: " + str(result.stderr))
        return False, result.stderr
    else:
        return True, None


def instrument(transformed_function_code):
    instrumentation_prompt = instrumentation_template.format(
        transformed_function_code=transformed_function_code)
    result = get_llm_result(instrumentation_prompt, [])
    return result
