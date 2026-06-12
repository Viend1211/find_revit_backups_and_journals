# Find Revit Backups And Journals

PowerShell script for searching Revit backup folders (`*_backup`), locating the corresponding `.rvt` model files, and finding references to these models in Revit Journal files across all installed Revit versions.

## Features

* Searches recursively through the current user's Documents folder.
* Detects Revit backup folders ending with `_backup`.
* Finds the corresponding `.rvt` file with the same name.
* Scans Revit Journal files for all installed Revit versions.
* Works on any Windows system regardless of username.
* Generates a CSV report.

## Requirements

* Windows 10 / 11
* PowerShell 5.1 or newer

## Quick Start

Open **PowerShell** and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
irm https://raw.githubusercontent.com/Viend1211/find_revit_backups_and_journals/main/find_revit_backups_and_journals.ps1 | iex
```

## Manual Download

```powershell
Invoke-WebRequest `
-Uri "https://raw.githubusercontent.com/Viend1211/find_revit_backups_and_journals/main/find_revit_backups_and_journals.ps1" `
-OutFile "find_revit_backups_and_journals.ps1"

.\find_revit_backups_and_journals.ps1
```

## What the script does

1. Searches the Documents folder for directories ending with `_backup`.
2. Removes the `_backup` suffix and checks whether a matching `.rvt` file exists.
3. Searches all Revit Journal folders located under:

```text
%LOCALAPPDATA%\Autodesk\Revit\
```

4. Looks through every installed Revit version:

   * Revit 2020
   * Revit 2021
   * Revit 2022
   * Revit 2023
   * Revit 2024
   * Revit 2025
   * and newer versions

5. Creates a CSV report containing:

   * Backup folder path
   * RVT file path
   * RVT existence status
   * Matching Journal files

## Output

The report is saved to:

```text
Documents\Revit_Backup_Report.csv
```

## Example

| Backup Folder   | RVT Exists | Journals Found |
| --------------- | ---------- | -------------- |
| Project_backup  | True       | 3              |
| Building_backup | False      | 0              |

## License

MIT License
