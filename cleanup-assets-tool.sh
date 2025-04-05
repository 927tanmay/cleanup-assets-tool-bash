#!/bin/bash

# --- Generalized Cleanup Script ---
# Usage: ./cleanup-assets.sh <ASSETS_DIR> <SEARCH_DIR>
# Example: ./cleanup-assets.sh src/assets src

# --- Input Arguments ---
ASSETS_DIR="$1"
SEARCH_DIR="$2"

# --- Validation ---
if [ -z "$ASSETS_DIR" ] || [ -z "$SEARCH_DIR" ]; then
  echo "Usage: $0 <ASSETS_DIR> <SEARCH_DIR>"
  echo "Example: $0 src/assets src"
  exit 1
fi

# --- Configurable Extensions and Exclusions ---
IMAGE_EXTENSIONS=(png jpg jpeg gif svg webp ico)
ROOT_FILES_TO_SEARCH=(
    "tailwind.config.js"
    "angular.json"
    "vite.config.js"
    "webpack.config.js"
)
EXCLUDE_DIRS=("node_modules" "dist" ".angular" "docs" "coverage" ".git" ".vscode") 
EXCLUDE_FILES=("*.spec.ts" "*.d.ts")

# --- Script Logic ---
echo "Starting search for unused images in '$ASSETS_DIR'..."
declare -a unused_images
unused_count=0
checked_count=0

if [ ! -d "$ASSETS_DIR" ]; then
    echo "Error: Assets directory '$ASSETS_DIR' not found."
    exit 1
fi

# Build find command
find_args=()
for ext in "${IMAGE_EXTENSIONS[@]}"; do
    find_args+=("-o" "-iname" "*.$ext")
done
find_args=(${find_args[@]:1})

# Build grep exclusions
grep_exclude_args=()
for dir in "${EXCLUDE_DIRS[@]}"; do
    grep_exclude_args+=("--exclude-dir=$dir")
done
for file_pattern in "${EXCLUDE_FILES[@]}"; do
    grep_exclude_args+=("--exclude=$file_pattern")
done

# Check each image
while IFS= read -r image_path; do
    ((checked_count++))
    image_name=$(basename "$image_path")
    search_targets=("$SEARCH_DIR")

    for root_file in "${ROOT_FILES_TO_SEARCH[@]}"; do
        [ -f "$root_file" ] && search_targets+=("$root_file")
    done

    if ! grep -rFIq "${grep_exclude_args[@]}" -- "$image_name" "${search_targets[@]}"; then
        echo "Potentially unused: $image_path"
        unused_images+=("$image_path")
        ((unused_count++))
    fi

done < <(find "$ASSETS_DIR" -type f \( "${find_args[@]}" \))

# Summary
echo "--------------------------------------------------"
echo "Search complete."
echo "Checked $checked_count image files."
echo "Found $unused_count potentially unused image files."

if [ "$unused_count" -gt 0 ]; then
    echo "IMPORTANT: Review the list above before deletion."
    read -p "Do you want to delete these files? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for image in "${unused_images[@]}"; do
            rm "$image"
            echo "Deleted: $image"
        done
        echo "Unused images deleted."
    else
        echo "No images were deleted."
    fi
fi

exit 0
