import os
import argparse

# from FineGrainedPartitionStrategy import main_advanced
# from SimplePartitionStrategy import main_simple
from src.framework.partition import split
from src.llmpartition import model_config

def main():
    parser = argparse.ArgumentParser(
        description="Analyze a Solidity contract or perform other tasks.")

    parser.add_argument("--solc", dest="solc", required=False,
                        type=str, default=None, help="Specify the solc to be used")
    parser.add_argument("--solc-remaps", dest="solc_remaps", required=False,
                        type=str, default=None, help="Specify file mappings to be used. different mappings are separated by delimiter")
    parser.add_argument(
        "--output_dir", dest="output_dir", type=str, required=False, default="./", help="output directory of the partitioned contract files.")
    parser.add_argument("--llm", dest="llm", required=False,
                        type=str, default="gpt-4o-mini", help="Specify LLM models to be used")

    subparsers = parser.add_subparsers(
        dest="command", required=True)  # required=True 强制要求输入子命令

    # 定义第一个子命令 'simple'，调用 main_simple 函数
    parser_simple = subparsers.add_parser(
        'simple', help="Execute the simple analysis task.")
    parser_simple.add_argument(
        "filepath", type=str, help="Path to the Solidity file.")
    parser_simple.add_argument(
        "target_contract_name", type=str, help="Name of the contract to analyze.")
    parser_simple.add_argument(
        "sensitive_var_name", type=str, help="Name of the sensitive variable to analyze.")

    # 定义第二个子命令 'advanced'，调用 main_advanced 函数
    parser_advanced = subparsers.add_parser(
        'advanced', help="Execute the advanced analysis task.")
    parser_advanced.add_argument(
        "filepath", type=str, help="Path to the Solidity file.")
    parser_advanced.add_argument(
        "target_contract_name", type=str, help="Name of the contract to analyze.")
    parser_advanced.add_argument(
        "sensitive_var_name", type=str, help="Name of the sensitive variable to analyze.")

    # 解析命令行参数
    args = parser.parse_args()

    solc_remaps = args.solc_remaps
    if solc_remaps:
        solc_remaps = args.solc_remaps.split(",")
    else:
        solc_remaps = []
        # 根据指定的子命令调用不同的函数
    if args.command is not None:
        if not os.path.exists(args.output_dir):
            os.mkdir(args.output_dir)
        model_config.LLM = args.llm 
        split(args.filepath, args.target_contract_name,
              args.sensitive_var_name, solc_remaps=solc_remaps, solc_version=args.solc, mode=args.command, outputdir=args.output_dir)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
