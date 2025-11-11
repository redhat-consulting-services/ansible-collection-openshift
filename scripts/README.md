# Scripts

This directory contains utility scripts for managing and processing actions related to the Ansible collection for OpenShift. These scripts can be used to extract version information, update configuration files, and perform other maintenance tasks.

## versions-extract.py

This script extracts the latest OpenShift versions from a specified URL and updates a YAML file with this information. It allows customization of the number of major/minor and patch versions to extract.

Arguments:

- `file_path`: The path to the YAML file to update.
- `--url`: (Optional) The URL to process for version extraction (default is `mirror.openshift.com`).`
- `--minor`: (Optional) The number of minor versions to extract (default is 3).
- `--patch`: (Optional) The number of patch versions to extract (default is 5).

Example usage:

```bash
python3 versions-extract.py .github/workflows/build-ee.yaml
```

### Execution

This script is typically executed as part of a GitHub Actions workflow to keep the OpenShift version matrix up to date automatically. See the `.github/workflows/update-version-matrix.yaml` file for an example of how this script is integrated into a CI/CD pipeline.
