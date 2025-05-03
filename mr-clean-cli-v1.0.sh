#!/bin/bash

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

# Check directory permissions
if ! check_directory_permissions "$directory_path"; then
    echo "⚠️  Error: Directory permissions check failed"
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