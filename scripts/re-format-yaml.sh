#!/bin/bash

SOURCE_DIR=${SOURCE_DIR:-./}

while IFS= read -r -d '' file; do
  echo "Reformatting $file"
  yq eval -P . "$file" > "$file.tmp" && mv "$file.tmp" "$file"
done < <(find "$SOURCE_DIR" -type f \( -name "*.yaml" -o -name "*.yml" \) -print0)
