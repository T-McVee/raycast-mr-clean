#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Mr. Clean v1.0
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🫧
# @raycast.needsConfirmation true
# @raycast.argument1 { "type": "text", "placeholder": "Directory path", "optional": true }

# Documentation:
# @raycast.description Organises files in the current directory into folders based on month created
# @raycast.author T-McVee
# @raycast.authorURL https://raycast.com/T-McVee

# turn on to use a custom directory


directory_path=$1

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

echo "--- Mr Clean is in the dir ---"
echo "Cleaning directory: $directory_path"

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

organise_directory "$directory_path" 