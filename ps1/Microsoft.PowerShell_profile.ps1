# Environment variables
# --------------------------

# Make `less` search case-insensitive by default.
# Use Windows version of `less`, since WSL `less` is broken in PowerShell.
$Env:LESS='-i'

# Remove bad aliases: reimplementations are below.
#
# `Remove-Item` is used since `Remove-Alias` is not available in PS 5.1
# ---------------------------------------------------------------------

Remove-Item alias:\rm
Remove-Item alias:\cd
Remove-Item alias:\diff -Force

# Functions
# ---------

# WSL command wrapper to make them work with Windows path
function WrapWSLCmd ($cmd) {
  return {
    $expr = 'wsl ' + $cmd

    for ($i=0; $i -lt $args.Count ; $i++) {
      $expr += ' '

      # Keep Vim options:
      if ( "$( $args[$i] )".StartsWith('-') ) {
        $expr += $args[$i]
        continue
      }

      $expr += '`"`$`(' + 'wslpath -a ' + "```'" + "$( $args[$i] )" + "```'" + '`)`"'
    }

    Invoke-Expression "$expr"
  }.GetNewClosure()
}

# `cd` reimplementation
function cd ( $location = '~' ) {
  if ( $location -eq '-' ) {
    $location = $Env:OLDPWD
  }

  $Env:OLDPWD = $( Get-Location )
  Set-Location $location
}

# `rm` reimplementation
function rm {
  Remove-Item -Confirm @args
}

# Wrap WSL commands work with Windows path
# ----------------------------------------

$Function:vim     = $(WrapWSLCmd('vim'))
$Function:vimdiff = $(WrapWSLCmd('vimdiff'))
$Function:view    = $(WrapWSLCmd('view'))
$Function:nano    = $(WrapWSLCmd('nano'))
$Function:diff    = $(WrapWSLCmd('diff'))
$Function:file    = $(WrapWSLCmd('file'))
$Function:gcc     = $(WrapWSLCmd('x86_64-w64-mingw32-gcc -static'))
$Function:gpp     = $(WrapWSLCmd('x86_64-w64-mingw32-g++ -static'))

# Aliases
# -------

New-Alias -Name "touch" -Value "New-Item"
New-Alias -Name "which" -Value "Get-Command"
New-Alias -Name "vi"    -Value "vim"
# New-Alias -Name "zip"   -Value Compress-Archive # I use `7z` from command line.
# New-Alias -Name "unzip" -Value Expand-Archive

# Tab completions
# ---------------

# Import Posh-Git before choco and scoop completion; the former breaks the rests.
Import-Module posh-git

# Github CLI
Invoke-Expression -Command $(gh completion -s powershell | Out-String)

# Chocolatey
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

# Scoop: Absolute path is used because PS Core does not # respect $env:PSModulePath.
Import-Module "$($(Get-Item $(Get-Command scoop.ps1).Path).Directory.Parent.FullName)\modules\scoop-completion"

