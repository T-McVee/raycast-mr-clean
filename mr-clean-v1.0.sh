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

# Source shared functions
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FUNCTIONS_FILE="$SCRIPT_DIR/mr-clean-functions.sh"

if [ ! -f "$FUNCTIONS_FILE" ]; then
    echo "Error: Cannot find functions file at $FUNCTIONS_FILE"
    exit 1
fi

if [ ! -x "$FUNCTIONS_FILE" ]; then
    echo "Error: Functions file is not executable. Running: chmod +x $FUNCTIONS_FILE"
    chmod +x "$FUNCTIONS_FILE"
fi

source "$FUNCTIONS_FILE" || {
    echo "Error: Failed to source functions file"
    exit 1
}

directory_path=$1
undo_cleaning=$2

# If no directory provided, get current Finder directory
if [ -z "$directory_path" ]; then
  directory_path=$(osascript -e 'tell application "Finder" to get POSIX path of (target of front window as alias)')

  echo "No directory provided, using current Finder directory: $directory_path"
fi

# handle invalid directory
if [ ! -d "$directory_path" ]; then
  echo "Please provide a valid directory to clean up."
  echo "Or, leave blank to use your current Finder directory."
  # echo "use -h or --help for more information"
  
  exit 1
fi

# Main execution #
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