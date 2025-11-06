import re
import requests
from collections import defaultdict
import yaml
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
        result.extend([f"v{mm}.{p}" for p in patches])

    return result

def update_yaml_with_versions(yaml_file: str, versions: list):
    # load existing YAML
    with open(yaml_file, "r") as f:
        data = yaml.safe_load(f)

    # navigate to the correct path and update versions
    data.setdefault("jobs", {}).setdefault("build", {}) \
        .setdefault("strategy", {}).setdefault("matrix", {})["openshift_version"] = versions

    # write back to the file
    with open(yaml_file, "w") as f:
        yaml.dump(data, f, sort_keys=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process a URL and file path with version info.")
    parser.add_argument("url", help="The URL to process. In most cases this should be mirror.openshift.com")
    parser.add_argument("file_path", help="The path to the file")
    parser.add_argument("--minor", type=int, default=3, help="Minor version number (default: 3)")
    parser.add_argument("--patch", type=int, default=5, help="Patch version number (default: 5)")
    args = parser.parse_args()

    url = f"https://{args.url}/pub/openshift-v4/clients/ocp/"
    versions = extract_latest_versions_from_url(url, args.minor, args.patch)

    yaml_file = args.file_path
    update_yaml_with_versions(yaml_file, versions)

    print(f"Updated {yaml_file} with the following versions:")
    print("\n".join(f"- {v}" for v in versions))
