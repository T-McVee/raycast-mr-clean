#!/bin/bash


print_help() {
    echo "Mr. Clean - Directory Organization Tool"
    echo "Usage: ./mr-clean.sh [OPTIONS] [DIRECTORY]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -u, --undo     Undo previous cleaning"
    echo ""
    echo "If no directory is specified, the current directory will be used."
}

# Parse command line arguments
directory_path="."
undo_cleaning=""
calling_card_file_name="mr_clean_was_here.txt"

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            print_help
            exit 0
            ;;
        -u|--undo)
            undo_cleaning="undo"
            shift
            ;;
        *)
            directory_path="$1"
            shift
            ;;
    esac
done


# If no directory provided, use current directory
if [ "$directory_path" = "." ]; then
    directory_path=$(pwd)
    echo "Using current directory: $directory_path"
fi

# handle invalid directory
if [ ! -d "$directory_path" ]; then
  echo "Please provide a valid directory to clean up."
  echo "Or, leave blank to use your current Finder directory."
  # echo "use -h or --help for more information"
  
  exit 1
fi


# Helper functions #
sort_files_by_date() {
  file=$1
  file_name=$(basename "$file")

  if [ -f "$file" ] && [ "$file_name" != "$calling_card_file_name" ]; then
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


# Main #
organise_directory() {
  target_dir_path=$1

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


echo "

         🫧 MR CLEAN IS IN THE DIR! 🧹

"

# If undo cleaning is true, flatten the directory
if [ "$undo_cleaning" = "u" ] || [ "$undo_cleaning" = "undo" ]; then
  echo "Undoing cleaning..."
  flatten_directory "$directory_path"
  exit 0
fi

organise_directory "$directory_path" 