#!/bin/bash

SOURCE_DIR ?= ${SOURCE_DIR:-./}

for file in $(find "$SOURCE_DIR" -type f -name "*.yaml" -o -name "*.yml"); do
  echo "Reformatting $file"
  yq eval -P . "$file" > "$file.tmp" && mv "$file.tmp" "$file"
done
