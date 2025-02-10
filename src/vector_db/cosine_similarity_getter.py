import os
from pathlib import Path
import pickle
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
import openai
import matplotlib.pyplot as plt
import src.vector_db.config as config


class EmbeddingAnalyzer:
    def __init__(self):
        self.load_embeddings()

    def load_embeddings(self):
        script_dir = Path(__file__).parent
        embeddings_file = script_dir / 'basic_data' / 'embeddings.pkl'
        if embeddings_file.exists():
            with open(embeddings_file, 'rb') as f:
                self.embeddings, self.metadata_list = pickle.load(f)
        else:
            raise FileNotFoundError(
                f"No embeddings file found at {embeddings_file}")

    def convert_to_embedding(self, input_text):
        openai.api_key = config.OPENAI_API_KEY
        response = openai.Embedding.create(
            model=config.PRETRAIN_MODEL_OPENAI,
            input=input_text
        )
        return response['data'][0]['embedding']

    def calculate_similarities(self, input_embedding):
        return cosine_similarity([input_embedding], list(self.embeddings.values()))[0]

    def get_top_k_similar(self, embeddings, metadata_list, input_embedding, k=5):
        # Calculate cosine similarity
        similarities = cosine_similarity(
            [input_embedding], list(self.embeddings.values()))[0]

        # Get top k indices from the top similarities up to the limit
        top_indices_limit = np.argsort(
            similarities)[-config.TOP_K:][::-1]

        # Get top k metadata and scores from the top similarities within the limit
        top_k_metadata = [metadata_list[i] for i in top_indices_limit[:k]]
        top_k_scores = [similarities[i] for i in top_indices_limit[:k]]

        return top_k_metadata, top_k_scores

    def find_elbow_point(self, similarities, m):
        # Ensure m is within the range of similarities
        # m should not be out of index range
        m = max(0, min(m, len(similarities) - 1))

        # Adjust the list of points to start from m
        points = [(i, s) for i, s in enumerate(similarities[m:])]
        p1, pn = points[0], points[-1]

        # Function to calculate distance of each point from line
        def distance_from_line(p, p1, pn):
            return np.abs((pn[1] - p1[1]) * p[0] - (pn[0] - p1[0]) * p[1] + pn[0] * p1[1] - pn[1] * p1[0]) / np.sqrt(
                (pn[1] - p1[1]) ** 2 + (pn[0] - p1[0]) ** 2)

        # Calculate the distance for each point
        distances = np.array([distance_from_line(p, p1, pn) for p in points])

        # The point with the maximum distance is our elbow point
        elbow_index = np.argmax(distances)
        return elbow_index + 1  # Adding 1 because indices start at 0

    def analyze_input(self, input_text):
        input_embedding = self.convert_to_embedding(input_text)
        similarities = self.calculate_similarities(input_embedding)

        m = 0
        sorted_similarities = np.sort(
            similarities)[-config.TOP_K:][::-1]
        top_k = self.find_elbow_point(sorted_similarities, m)

        top_k_metadata, top_k_scores = self.get_top_k_similar(
            self.embeddings, self.metadata_list, input_embedding, k=top_k)

        return [(metadata['Original'], metadata['Partition'], score) for metadata, score in zip(top_k_metadata, top_k_scores)]


# # 使用示例
# analyzer = EmbeddingAnalyzer()
# input_word = '''
# function withdraw(
#     uint256 _shares,
#     address _recipient,
#     uint256 maxSlippage
#   ) public returns (uint256) {
#     // mirror real vault behavior
#     if (_shares == type(uint256).max) {
#       _shares = balanceOf(msg.sender);
#     }
#     uint256 _r = (balance() * _shares) / totalSupply();
#     _burn(msg.sender, _shares);

#     // apply mock slippage
#     uint256 withdrawnAmt = _r - (_r * forcedSlippage) / PERCENT_RESOLUTION;
#     require(withdrawnAmt >= _r - (_r * maxSlippage) / PERCENT_RESOLUTION, "too much slippage");


#     TokenUtils.safeTransfer(token, _recipient, _r);
#     return _r;
#   }

#  '''
# results = analyzer.analyze_input(input_word)
# for i, (original, partition, score) in enumerate(results, start=1):
#     print(f"{i}. Score: {score:.4f}, Original: {original}, Partition: {partition}")
