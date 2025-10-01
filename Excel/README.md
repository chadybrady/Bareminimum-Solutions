# Excel Scripts

This directory contains PowerShell scripts for Excel file manipulation and conversion utilities.

## Scripts

### ConvertCSVToExcel
**File**: `ConvertCSVToExcel.ps1`

Converts CSV files to Excel format with proper formatting and encoding. This script processes all CSV files in a source directory and outputs formatted Excel files.

**Features**:
- Batch conversion of multiple CSV files
- Interactive directory selection
- Automatic destination directory creation
- Preserves data integrity during conversion
- Progress feedback for each file

**Prerequisites**: 
- `ImportExcel` PowerShell module (automatically installed by script)

**Usage**:
```powershell
.\ConvertCSVToExcel.ps1
```

The script will prompt for:
1. Source directory path (where CSV files are located)
2. Destination directory path (where Excel files will be saved)

**Example**:
```powershell
# Run the script
.\ConvertCSVToExcel.ps1

# Enter source directory when prompted:
# C:\Data\CSVFiles

# Enter destination directory when prompted:
# C:\Data\ExcelFiles
```

## Module Information

The script uses the **ImportExcel** module, which provides:
- Excel file creation without requiring Excel to be installed
- Support for multiple worksheets
- Formatting options
- Cross-platform compatibility

## Notes

- The destination directory will be created automatically if it doesn't exist
- All CSV files in the source directory will be processed
- Original CSV files remain unchanged
- Excel files are created with the same base filename as the CSV
