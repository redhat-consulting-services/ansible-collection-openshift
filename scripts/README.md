# Scripts

This directory contains utility scripts for managing and processing actions related to the Ansible collection for OpenShift. These scripts can be used to extract version information, update configuration files, and perform other maintenance tasks.

## versions-extract.py

This script extracts the latest OpenShift versions from a specified URL and updates a YAML file with this information. It allows customization of the number of major/minor and patch versions to extract.

Arguments:

- `url`: The URL to process for version extraction. In most cases, this should be set to `mirror.openshift.com`.
- `file_path`: The path to the YAML file to update.
- `--minor`: (Optional) The number of minor versions to extract (default is 3).
- `--patch`: (Optional) The number of patch versions to extract (default is 5).

Example usage:

```bash
python3 versions-extract.py mirror.openshift.com .github/workflows/build-ee.yaml
```
