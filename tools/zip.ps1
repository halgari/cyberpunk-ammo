# Zips a directory with forward-slash entry names. Windows PowerShell's Compress-Archive and
# .NET Framework's CreateFromDirectory write backslashes, which some mod managers mis-extract.
param(
    [Parameter(Mandatory)][string]$Source,
    [Parameter(Mandatory)][string]$Destination
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$Source = (Resolve-Path $Source).Path.TrimEnd('\')
$archive = [IO.Compression.ZipFile]::Open($Destination, 'Create')
try {
    foreach ($file in Get-ChildItem $Source -Recurse -File) {
        $name = $file.FullName.Substring($Source.Length + 1).Replace('\', '/')
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $name) | Out-Null
    }
}
finally {
    $archive.Dispose()
}
