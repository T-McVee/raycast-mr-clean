# Mr. Clean 🫧

A Raycast script that automatically organizes files and folders by their creation date.

## Features

- Organizes files into folders based on creation month (YYYY-MM format)
- Automatically archives folders older than 6 months into an `_archive` directory
- Works with the current Finder window or a specified directory path
- Leaves a friendly timestamp when cleaning is complete

## Prerequisites

- macOS
- [Raycast](https://raycast.com/) installed
- Bash shell

## Usage

### Via Raycast

1. Open Raycast
2. Type "Mr. Clean"
3. Optionally provide a directory path, or leave blank to use current Finder window
4. Confirm the action

### Directory Structure

The script will organize your files into the following structure:
your-directory/
├── 2024-03/
├── 2024-02/
├── 2024-01/
├── _archive/
│ ├── 2023-09/
│ ├── 2023-08/
│ └── ...
└── mr_clean_was_here.txt

## How It Works

1. If no directory is specified, the script uses the current Finder window location
2. Files and folders are sorted into monthly directories (YYYY-MM format)
3. Monthly folders older than 6 months are moved to the `_archive` directory
4. A timestamp file (`mr_clean_was_here.txt`) is created in the source directory

## Author

Created by T-McVee  
[Author Profile](https://raycast.com/T-McVee)

## License

This project is open source and available under the MIT License.