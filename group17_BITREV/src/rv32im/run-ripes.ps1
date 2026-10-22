[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RipesPath,
    [string]$SourcePath = (Join-Path $PSScriptRoot 'bitrev.S'),
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '../../report/cp2-b')
)
$ErrorActionPreference = 'Stop'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$repo = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
function Get-RepoRelativePath([string]$path) {
    $prefix = $repo.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    if (-not $path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Source and output must be inside the repository.'
    }
    return $path.Substring($prefix.Length).Replace('\', '/')
}
$exe = (Resolve-Path -LiteralPath $RipesPath).Path
$source = (Resolve-Path -LiteralPath $SourcePath).Path
$vectorsPath = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../c_baseline/test_vectors.h')).Path
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$out = (Resolve-Path -LiteralPath $OutputDirectory).Path
$stdout = Join-Path $out 'ripes-stdout.txt'
$stderr = Join-Path $out 'ripes-stderr.txt'
$report = Join-Path $out 'ripes-registers.txt'
$relativeSource = Get-RepoRelativePath $source
$relativeReport = Get-RepoRelativePath $report
# Start-Process needs explicit quoting for paths containing spaces.
if ($source.Contains('"') -or $report.Contains('"')) { throw 'Unsupported quote in path.' }
$arguments = '--mode cli --src "' + $relativeSource + '" -t asm --proc RV32_5S --isaexts M --timeout 30000 --regs --runinfo --output "' + $relativeReport + '"'
$command = 'Ripes.exe ' + $arguments
[IO.File]::WriteAllText((Join-Path $out 'command.txt'), $command + [Environment]::NewLine, $utf8)
$sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
$process = Start-Process -FilePath $exe -ArgumentList $arguments -WorkingDirectory $repo -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant() -ne $sourceHash) { throw 'Source changed during simulation.' }
# Normalize telemetry paths and trailing blank lines without changing register data.
foreach ($log in @($stdout, $stderr, $report)) {
    if (Test-Path -LiteralPath $log) {
        $content = [IO.File]::ReadAllText($log, $utf8).Replace($source, $relativeSource)
        $content = $content.Replace($repo.Replace('\', '/') + '/', '').Replace($repo + '\', '')
        $content = $content.Replace("`r`n", "`n").TrimEnd("`r", "`n")
        if ($content.Length -gt 0) { $content += "`n" }
        [IO.File]::WriteAllText($log, $content, $utf8)
    }
}
$text = [IO.File]::ReadAllText($stdout, $utf8)
Write-Output $text
if ($process.ExitCode -ne 0) { throw "Ripes exit code: $($process.ExitCode). See $stderr" }
if (-not (Test-Path -LiteralPath $report)) { throw 'Ripes did not produce the register report.' }
$reference = [regex]::Matches([IO.File]::ReadAllText($vectorsPath, $utf8), '\{\s*0x([0-9A-Fa-f]{8})u,\s*0x([0-9A-Fa-f]{8})u,')
$rows = [regex]::Matches($text, '(?m)^T(\d+) in=0x([0-9A-Fa-f]{8}) exp=0x([0-9A-Fa-f]{8}) act=0x([0-9A-Fa-f]{8}) (PASS|FAIL)\s*$')
if ($reference.Count -ne 11 -or $rows.Count -ne $reference.Count) { throw 'Expected all 11 CP1 vectors and all 11 Ripes result lines.' }
$table = @('| # | Input | Expected | Actual | Result |', '|---|---|---|---|---|')
for ($i = 0; $i -lt $reference.Count; $i++) {
    $g = $rows[$i].Groups
    $expected = $reference[$i].Groups
    if ([int]$g[1].Value -ne ($i + 1) -or $g[2].Value -ine $expected[1].Value -or $g[3].Value -ine $expected[2].Value -or $g[4].Value -ine $expected[2].Value -or $g[5].Value -ne 'PASS') {
        throw "Vector $($i + 1) differs from CP1 or failed."
    }
    $table += '| ' + ($i + 1) + ' | 0x' + $g[2].Value + ' | 0x' + $g[3].Value + ' | 0x' + $g[4].Value + ' | PASS |'
}
if ($text -notmatch '(?m)^PASSED=11 FAILED=0\s*$' -or $text -notmatch 'Program exited with code: 0') { throw 'Missing successful summary or program exit.' }
$registers = [IO.File]::ReadAllText($report, $utf8)
foreach ($check in @(@(18, 11), @(19, 11), @(20, 0))) {
    $pattern = '(?m)^x' + $check[0] + ':\s+' + $check[1] + '\s+\('
    if ($registers -notmatch $pattern) { throw "Unexpected final x$($check[0]) value." }
}
[IO.File]::WriteAllText((Join-Path $out 'test-results.md'), ($table -join [Environment]::NewLine) + [Environment]::NewLine, $utf8)
$manifest = [ordered]@{
    executed_at = (Get-Date).ToString('o')
    processor = 'RV32_5S'; isa_extensions = 'M'; ripes_exit_code = $process.ExitCode
    source_sha256 = $sourceHash
    vectors_sha256 = (Get-FileHash -LiteralPath $vectorsPath -Algorithm SHA256).Hash
    ripes_exe_sha256 = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
    vector_count = $rows.Count; passed = 11; failed = 0; command = $command
}
[IO.File]::WriteAllText((Join-Path $out 'manifest.json'), ($manifest | ConvertTo-Json), $utf8)
Write-Output 'Verified: all 11 outputs match CP1; s2=11, s3=11, s4=0.'
