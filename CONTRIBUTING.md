# Contributing to Bareminimum Solutions

Thank you for your interest in contributing to Bareminimum Solutions! This document provides guidelines and standards for contributing to this repository.

## 🎯 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear and descriptive title**
- **Detailed description** of the issue
- **Steps to reproduce** the problem
- **Expected behavior** vs actual behavior
- **PowerShell version** and OS information
- **Screenshots** if applicable
- **Error messages** (full text)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear and descriptive title**
- **Detailed description** of the proposed functionality
- **Use cases** that would benefit from this enhancement
- **Examples** of similar features in other tools (if applicable)

### Pull Requests

1. **Fork the repository** and create your branch from `main`
2. **Follow the coding standards** outlined below
3. **Test your changes** thoroughly
4. **Update documentation** as needed
5. **Ensure your code follows** the existing style
6. **Write a clear commit message**

## 📝 Coding Standards

### PowerShell Script Guidelines

#### File Naming
- Use **PascalCase** for script filenames (e.g., `GetAllUsers.ps1`)
- Use descriptive names that clearly indicate the script's purpose
- Avoid abbreviations unless they're well-known (e.g., `PP` for Power Platform)

#### Folder Structure
- Use **kebab-case** for folder names (e.g., `Create-Break-Glass-Accounts`)
- Group related scripts in logical directories
- Each major script or feature should have its own subdirectory

#### Script Structure
```powershell
# Script header with metadata
#Requires -Version 5.1
#Requires -Modules Microsoft.Graph

<#
.SYNOPSIS
    Brief description of what the script does

.DESCRIPTION
    Detailed description of the script's functionality

.PARAMETER ParameterName
    Description of the parameter

.EXAMPLE
    .\ScriptName.ps1 -Parameter "Value"
    Description of what this example does

.NOTES
    Author: Your Name
    Created: YYYY-MM-DD
    Version: 1.0
#>

# Parameters
param(
    [Parameter(Mandatory = $true)]
    [string]$Parameter1
)

# Script content
```

#### Code Style
- Use **meaningful variable names** with descriptive prefixes:
  - `$userCount` not `$uc`
  - `$groupId` not `$gid`
- **Indent with 4 spaces** (not tabs)
- Use **cmdlet-approved verbs** (Get, Set, New, Remove, etc.)
- Include **error handling** with try-catch blocks
- Add **comments** for complex logic
- Use **Write-Host** with colors for user feedback:
  ```powershell
  Write-Host "Success message" -ForegroundColor Green
  Write-Host "Warning message" -ForegroundColor Yellow
  Write-Host "Error message" -ForegroundColor Red
  ```

#### Module Management
```powershell
# Check and install required modules
$requiredModules = @('Microsoft.Graph', 'Microsoft.Entra')

foreach ($module in $requiredModules) {
    if (-not (Get-Module -Name $module -ListAvailable)) {
        Write-Host "Installing module: $module" -ForegroundColor Yellow
        Install-Module -Name $module -Force -Scope CurrentUser
    }
}

# Import modules
Import-Module Microsoft.Graph
```

#### Error Handling
```powershell
try {
    # Your code here
    Connect-MgGraph -Scopes "User.Read.All"
    Write-Host "Successfully connected" -ForegroundColor Green
}
catch {
    Write-Error "Failed to connect: $($_.Exception.Message)"
    exit 1
}
```

### Documentation Standards

#### README Files
Every script directory should include a `README.md` file with:

1. **Title and Description**: Clear explanation of what the script does
2. **Features**: Bullet list of key features
3. **Prerequisites**: Required modules and permissions
4. **Usage**: Example commands and parameters
5. **Important Notes**: Warnings, limitations, or special considerations
6. **Examples**: Real-world usage examples

#### Script Comments
- Use `#` for single-line comments
- Use `<# ... #>` for multi-line comments and help blocks
- Comment complex logic and non-obvious code
- Explain WHY, not just WHAT
- Keep comments up-to-date with code changes

## 🧪 Testing

Before submitting a pull request:

1. **Test in a non-production environment**
2. **Verify all parameters work as expected**
3. **Test error handling** with invalid inputs
4. **Check for unintended side effects**
5. **Verify module dependencies** are correctly specified
6. **Test with different permission levels** if applicable

## 📚 Documentation Updates

When adding or modifying scripts:

1. **Update the main README.md** with a link to your script
2. **Create/update the subdirectory README.md** with detailed information
3. **Include inline script documentation** (synopsis, description, examples)
4. **Update prerequisites** if new modules are required
5. **Add usage examples** that others can follow

## 🔒 Security Considerations

- **Never commit credentials** or sensitive information
- **Use secure methods** for credential handling (Get-Credential)
- **Validate user input** to prevent injection attacks
- **Use least privilege** principles in permission requirements
- **Warn users** about potentially destructive operations
- **Include security notes** in documentation

## 📋 Commit Message Guidelines

Write clear and meaningful commit messages:

```
Add Get-UserLicenses script for license reporting

- Retrieves all user licenses from Microsoft 365
- Exports to CSV with detailed license information
- Includes error handling and progress reporting
```

Format:
- **First line**: Brief summary (50 chars or less)
- **Blank line**
- **Body**: Detailed explanation of changes (wrap at 72 chars)
- Use **present tense** ("Add feature" not "Added feature")
- Use **imperative mood** ("Move cursor to..." not "Moves cursor to...")

## 🎨 Style Preferences

### PowerShell Preferences
- Use **splatting** for cmdlets with multiple parameters:
  ```powershell
  $params = @{
      Identity = $userId
      Property = @('DisplayName', 'UserPrincipalName')
      ErrorAction = 'Stop'
  }
  Get-MgUser @params
  ```
- Use **pipeline** when appropriate
- Prefer **approved cmdlets** over .NET methods when available
- Use **Write-Verbose** for debugging information
- Use **Write-Progress** for long-running operations

## 📞 Questions?

If you have questions about contributing:
- **Open an issue** with the "question" label
- **Review existing issues** for similar questions
- **Check the documentation** in README files

## 📄 License

By contributing, you agree that your contributions will be licensed under the same MIT License that covers the project.

---

Thank you for contributing to Bareminimum Solutions! 🎉
