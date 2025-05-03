#!/bin/bash

# Constants #
export CALLING_CARD_FILE_NAME="mr_clean_was_here.txt"

# Helper functions #
sort_files_by_date() {
  file=$1
  file_name=$(basename "$file")

  if [ -f "$file" ] && [ "$file_name" != "$CALLING_CARD_FILE_NAME" ]; then
    sort_by_date "$file"
  fi
}

sort_folders_by_date() {
  folder=$1
  folder_name=$(basename "$folder")

  if [ -d "$folder" ]; then
    if [[ ! $folder_name =~ ^[0-9]{4}-[0-9]{2}$ && $folder_name != "_archive" ]]; then
      sort_by_date "$folder"
    fi
  fi
}

sort_by_date() {
  local entity=$1
  local entity_name=$(basename "$entity")
  local parent_dir=$(dirname "$entity")

  # get the creation time in seconds
  local entity_creation_time=$(stat -f "%B" "$entity")

  # convert the creation time to a human readable format
  local entity_creation_month=$(date -r "$entity_creation_time" "+%Y-%m")
  
   # Remove trailing slash from target_dir_path if it exists
  local clean_path="${target_dir_path%/}"

  echo "Moving $entity_name to $clean_path/$entity_creation_month"

  # create a directory with the creation month if it doesn't exist
  if [ ! -d "$clean_path/$entity_creation_month" ]; then
    mkdir "$clean_path/$entity_creation_month"
  fi
  
  mv "$entity" "$clean_path/$entity_creation_month/"
}

archive_old_files() {
  local folder=$1
  local folder_name=$(basename "$folder")
  
  # Only process folders that match YYYY-MM format
  if [[ $folder_name =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
    local folder_creation_month=$(date -j -f "%Y-%m" "$folder_name" "+%s")
    local current_month=$(date "+%s")
    local six_months_ago=$(date -v-6m "+%s")

    # Create archive folder if it doesn't exist
    if [ ! -d "$target_dir_path/_archive" ]; then
      echo "Creating archive folder"
      mkdir "$target_dir_path/_archive"
    fi

    if [ $folder_creation_month -lt $six_months_ago ]; then
      echo "Moving $folder_name to $target_dir_path/_archive"
      mv "$folder" "$target_dir_path/_archive"
      else
        echo "Keeping $folder_name (less than 6 months old)"
    fi
  fi
}

check_safe_directory() {
    local dir_to_check="$1"
    
    # Convert to absolute path
    dir_to_check=$(cd "$dir_to_check" 2>/dev/null && pwd)
    if [ $? -ne 0 ]; then
        echo "⚠️  Error: Directory does not exist or is not accessible: $dir_to_check"
        exit 1
    fi

    # Define allowed parent directories
    allowed_dirs=(
        "$HOME/Downloads"
        "$HOME/Documents"
        "$HOME/Desktop"
        "$HOME/Pictures"
    )

    # Check if directory is in allowed list or is a subdirectory of allowed directories
    allowed=0
    for allowed_dir in "${allowed_dirs[@]}"; do
        if [[ "$dir_to_check" == "$allowed_dir" || "$dir_to_check" == "$allowed_dir"/* ]]; then
            allowed=1
            break
        fi
    done

    if [ $allowed -eq 0 ]; then
        echo "⚠️  Error: Mr. Clean can only run in these directories (or their subdirectories):"
        printf "   - %s\n" "${allowed_dirs[@]}"
        echo ""
        echo "Current directory: $dir_to_check"
        exit 1
    fi

}

check_directory_permissions() {
    local dir="$1"
    
    # Check basic access
    if [ ! -d "$dir" ]; then
        echo "⚠️  Error: Not a directory: $dir"
        return 1
    fi
    
    # Check read/write/execute permissions
    if [ ! -r "$dir" ]; then
        echo "⚠️  Error: No read permission in $dir"
        return 1
    fi
    if [ ! -w "$dir" ]; then
        echo "⚠️  Error: No write permission in $dir"
        return 1
    fi
    if [ ! -x "$dir" ]; then
        echo "⚠️  Error: No execute permission in $dir"
        return 1
    fi
    
    # Check if we can create and remove files
    if ! touch "$dir/.mr_clean_test" 2>/dev/null; then
        echo "⚠️  Error: Cannot create files in $dir"
        return 1
    fi
    rm -f "$dir/.mr_clean_test"
    
    return 0
}

# Main functions #
organise_directory() {
  local target_dir_path=${1%/}  # Remove trailing slash if present

  check_safe_directory "$target_dir_path"

  echo "Cleaning directory: $target_dir_path"

  # get the last segment of the target directory path
  target_dir_name="$(basename "$target_dir_path")"

  echo "Cleaning up the "$target_dir_name" directory"


  # Sort files in the Downloads directory into folders based on the creation month
  for file in "$target_dir_path"/*; do
    sort_files_by_date "$file"
  done

  # Sort folders in the Downloads directory into folders based on the creation month
  for folder in "$target_dir_path"/*; do
    sort_folders_by_date "$folder"
  done

  # Move folders for files older than 6 months to an archive folder
  for folder in "$target_dir_path"/*; do
    archive_old_files "$folder"
  done

  #  Create mr clean was here file in the source directory
  if [ "$target_dir_path" = "$directory_path" ]; then
    echo "Last visited by Mr. Clean on $(date)" > "$target_dir_path/$calling_card_file_name"
  fi
}

flatten_directory() {
  local target_dir=$1

  check_safe_directory "$target_dir"
  echo "Flattening directory structure in: $target_dir"

  # Move everything from _archive back to the target directory
  if [ -d "$target_dir/_archive" ]; then
    echo "Moving files from _archive back to $target_dir..."
    
    # First move folders
    find "$target_dir/_archive" -type d -not -path "$target_dir/_archive" -exec mv {} "$target_dir/" \;

    # Then move remaining files
    find "$target_dir/_archive" -type f -exec mv {} "$target_dir/" \;
    rm -rf "$target_dir/_archive"
  fi

  # Move all fiels from YYYY-MM folders back to the target directory
  for folder in "$target_dir"/*; do
      folder_name=$(basename "$folder")
      
      # Check if folder matches YYYY-MM pattern
      if [[ -d "$folder" && $folder_name =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
          echo "Moving contents from $folder_name back to main directory..."
          # First move folders
          find "$folder" -type d -not -path "$folder" -exec mv {} "$target_dir/" \;
          # Then move remaining files
          find "$folder" -type f -exec mv {} "$target_dir/" \;
          rm -rf "$folder"
      fi
  done

  # Remove the calling card if it exists
  if [ -f "$target_dir/$calling_card_file_name" ]; then
      rm "$target_dir/$calling_card_file_name"
  fi
  
  echo "Directory structure has been flattened!"
}

# Export all functions that need to be accessible
export -f sort_files_by_date
export -f sort_folders_by_date
export -f sort_by_date
export -f archive_old_files
export -f check_safe_directory
export -f check_directory_permissions
export -f organise_directory
export -f flatten_directory