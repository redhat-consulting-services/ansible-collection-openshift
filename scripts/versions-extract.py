import re
import requests
from collections import defaultdict
import yaml

def extract_latest_versions_from_url(url: str, num_majorminor: int = 3, num_patch: int = 5):
    response = requests.get(url)
    response.raise_for_status()
    text = response.text

    # Extract versions, ignore RCs
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
    # Load existing YAML
    with open(yaml_file, "r") as f:
        data = yaml.safe_load(f)

    # Navigate to the correct path and update versions
    data.setdefault("jobs", {}).setdefault("build", {}) \
        .setdefault("strategy", {}).setdefault("matrix", {})["openshift_version"] = versions

    # Write back to the file
    with open(yaml_file, "w") as f:
        yaml.dump(data, f, sort_keys=False)

if __name__ == "__main__":
    url = "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/"
    versions = extract_latest_versions_from_url(url)

    yaml_file = "../.github/workflows/build-ee.yaml"
    update_yaml_with_versions(yaml_file, versions)

    print(f"Updated {yaml_file} with the following versions:")
    print("\n".join(f"- {v}" for v in versions))
