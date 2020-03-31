#!/usr/bin/env pwsh

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string] $Version
);

<#
    .SYNOPSIS
        Updates the contents of this repo to use a given version of
        the Quantum Development Kit.
        
    .PARAMETER Version
        The version that this repo should be updated to. This version should be
        a valid NuGet package version as well as a valid tag for the
        mcr.microsoft.com/quantum/iqsharp-base Docker image.
        
    .EXAMPLE
    
        PS> ./Update-QDKVersion.ps1 -Version 0.10.2002.2610
#>

$katasRoot = Join-Path $PSScriptRoot "\..\"

$csString = 'PackageReference Include=\"Microsoft\.Quantum\.[a-zA-Z\.]+\" Version=\"(?<oldVersion>[0-9|\.]+)\"'
$csFiles = (Get-ChildItem -Path $katasRoot -file -Recurse -Include "*.csproj" | ForEach-Object { Select-String -Path $_ -Pattern "Microsoft.Quantum" } | Select-Object -Unique Path)
$csFiles | ForEach-Object {
    (Get-Content -Encoding UTF8 $_.Path) | ForEach-Object {
         $isQuantumPackage = $_ -match $csString
         if ($isQuantumPackage) {
             $_ -replace $Matches.oldVersion, $Version
         } else {
             $_
         }
    } | Set-Content -Encoding UTF8 $_.Path
}

$ipynbString = '%package Microsoft.Quantum.Katas::(?<oldVersion>[0-9|\.]+)'
$ipynbFiles =  (Get-ChildItem -Path $katasRoot -file -Recurse -Include "*.ipynb" | ForEach-Object { Select-String -Path $_ -Pattern "Microsoft.Quantum" } | Select-Object -Unique Path)
$ipynbFiles | ForEach-Object {
    if ($_)
    {
        (Get-Content $_.Path) | ForEach-Object {
            $isQuantumPackage = $_ -match $ipynbString
            if ($isQuantumPackage) {
                $_ -replace $Matches.oldVersion, $Version
            } else {
                $_
            }
        } | Set-Content $_.Path
    }
}
$dockerString = 'FROM mcr.microsoft.com/quantum/iqsharp-base:(?<oldVersion>[0-9|\.]+)'
$dockerPath = Join-Path $katasRoot "Dockerfile"
(Get-Content -Path $dockerPath) | ForEach-Object {
         $isQuantumPackage = $_ -match $dockerString
         if ($isQuantumPackage) {
             $_ -replace $Matches.oldVersion, $Version
         } else {
             $_
         }
    } | Set-Content -Path $dockerPath


$ps1String = 'Microsoft.Quantum.IQSharp --version 0.11.2003.3107
$ps1Path = Join-Path $katasRoot "scripts\install-iqsharp.ps1"
(Get-Content -Path $ps1Path) | ForEach-Object {
         $isQuantumPackage = $_ -match $ps1String
         if ($isQuantumPackage) {
             $_ -replace $Matches.oldVersion, $Version
         } else {
             $_
         }
    } | Set-Content -Path $ps1Path

