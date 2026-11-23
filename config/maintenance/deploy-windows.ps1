[CmdletBinding()]
param(
    [switch]$Apply,
    [string]$Revision = 'HEAD',
    [string]$Vim = 'vim.exe'
)
$ErrorActionPreference = 'Stop'
$arguments = @("$PSScriptRoot/portable-setup.py", 'deploy', '--revision', $Revision, '--vim', $Vim)
if ($Apply) { $arguments += '--apply' }
py -3 @arguments
exit $LASTEXITCODE
