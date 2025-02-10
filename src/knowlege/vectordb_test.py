from vectordb import Memory

# Memory is where all content you want to store/search goes.
memory = Memory()

memory.save(
    # save your text content. for long text we will automatically chunk it
    ["apples are green", "oranges are orange"],
    # associate any kind of metadata with it (optional)
    [{"url": "https://apples.com"}, {"url": "https://oranges.com"}],
)

# Search for top n relevant results, automatically using embeddings
query = "green"
results = memory.search(query, top_n=1)

print(results)
