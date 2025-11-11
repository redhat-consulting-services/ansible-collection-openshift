import re
import requests
from collections import defaultdict
import json
import argparse

def extract_latest_versions_from_url(url: str, num_majorminor: int = 3, num_patch: int = 5):
    response = requests.get(url)
    response.raise_for_status()
    text = response.text

    # extract versions from html schema, ignore release candidates
    versions = re.findall(r'\b(\d+\.\d+\.\d+)(?!-rc)\b', text)
    versions = list(set(versions))  # remove duplicates

    grouped = defaultdict(list)
    for v in versions:
        major_minor = '.'.join(v.split('.')[:2])
        patch = int(v.split('.')[2])
        grouped[major_minor].append(patch)

    sorted_major_minor = sorted(grouped.keys(), key=lambda x: list(map(int, x.split('.'))))
    last_major_minor = sorted_major_minor[-num_majorminor:]

    result = []
    for mm in last_major_minor:
        patches = sorted(grouped[mm])[-num_patch:]
        result.extend([f"{mm}.{p}" for p in patches])

    return result

def update_json_with_versions(json_file: str, versions: list):
    # create JSON structure
    data = {
        "openshift_versions": versions
    }

    # write to the file
    with open(json_file, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")  # add trailing newline

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process a URL and file path with version info.")
    parser.add_argument("file_path", help="The path to the JSON file")
    parser.add_argument("--url", type=str, default="mirror.openshift.com", help="The URL to process (default: mirror.openshift.com)")
    parser.add_argument("--minor", type=int, default=3, help="Minor version number (default: 3)")
    parser.add_argument("--patch", type=int, default=5, help="Patch version number (default: 5)")
    args = parser.parse_args()

    url = f"https://{args.url}/pub/openshift-v4/clients/ocp/"
    versions = extract_latest_versions_from_url(url, args.minor, args.patch)

    json_file = args.file_path
    update_json_with_versions(json_file, versions)

    print(f"Updated {json_file} with the following versions:")
    print("\n".join(f"- {v}" for v in versions))
