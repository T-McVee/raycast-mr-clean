#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Mr. Clean v1.0
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🫧
# @raycast.needsConfirmation true
# @raycast.argument1 { "type": "text", "placeholder": "Directory path", "optional": true }
# @raycast.argument2 { "type": "text", "placeholder": "Undo cleaning?", "optional": true }

# Documentation:
# @raycast.description Organises files in the current directory into folders based on month created
# @raycast.author T-McVee
# @raycast.authorURL https://raycast.com/T-McVee

# turn on to use a custom directory


directory_path=$1
undo_cleaning=$2

echo "directory_path: $directory_path"
echo "undo_cleaning: $undo_cleaning"

# If no directory provided, get current Finder directory
if [ -z "$directory_path" ]; then
  directory_path=$(osascript -e 'tell application "Finder" to get POSIX path of (target of front window as alias)')

  echo "No directory provided, using current Finder directory: $directory_path"
fi

# handle no arguments
if [ ! -d "$directory_path" ]; then
  echo "Please provide a valid directory to clean up."
  echo "Or, leave blank to use your current Finder directory."
  # echo "use -h or --help for more information"
  
  exit 1
fi

echo "

         🧼 MR CLEAN IS IN THE DIR! 🧹

"


calling_card_file_name="mr_clean_was_here.txt"



# Helper functions

# Sort files and folders
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

# Main
organise_directory() {
  target_dir_path=$1

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

# If undo cleaning is true, flatten the directory
if [ "$undo_cleaning" = "u" ] || [ "$undo_cleaning" = "undo" ]; then
  echo "Undoing cleaning..."
  flatten_directory "$directory_path"
  exit 0
fi

organise_directory "$directory_path" 