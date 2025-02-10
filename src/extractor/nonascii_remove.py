import re


def remove_non_ascii_for_a_file(file_name):
    text = open(file_name, 'r').read().strip()
    text = remove_non_ascii(text)
    open(file_name, 'w').write(text)


def remove_non_ascii(text):
    return re.sub(r'[^\x00-\x7F]', ' ', text)
