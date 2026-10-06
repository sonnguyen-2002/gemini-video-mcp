param([switch]$CheckOnly)
$ErrorActionPreference = 'Stop'

function Find-Python {
    $candidates = @()
    foreach ($name in @('py.exe', 'python.exe')) {
        $entry = Get-Command $name -ErrorAction SilentlyContinue
        if ($entry) {
            if ($name -eq 'py.exe') { $candidates += @{Exe=$entry.Source; Args=@('-3')} }
            else { $candidates += @{Exe=$entry.Source; Args=@()} }
        }
    }
    $runtime = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
    if (Test-Path -LiteralPath $runtime) { $candidates += @{Exe=$runtime; Args=@()} }
    foreach ($candidate in $candidates) {
        try {
            $arguments = $candidate.Args + @('-c', 'import sys; assert sys.version_info >= (3,10); import venv; print(sys.executable)')
            $found = & $candidate.Exe @arguments 2>$null
            if ($LASTEXITCODE -eq 0 -and $found) { return ($found | Select-Object -Last 1).Trim() }
        } catch { }
    }
    return $null
}

function Find-Codex {
    $entry = Get-Command codex.exe -ErrorAction SilentlyContinue
    if ($entry) { return $entry.Source }
    $desktop = Join-Path $env:LOCALAPPDATA 'OpenAI\Codex\bin'
    if (Test-Path -LiteralPath $desktop) {
        $found = Get-ChildItem -LiteralPath $desktop -Filter codex.exe -Recurse -File |
            Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($found) { return $found.FullName }
    }
    $packages = Get-AppxPackage -Name '*Codex*' -ErrorAction SilentlyContinue
    foreach ($package in $packages) {
        if ($package.InstallLocation) {
            $found = Get-ChildItem -LiteralPath $package.InstallLocation -Filter codex.exe -Recurse -File -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if ($found) { return $found.FullName }
        }
    }
    return $null
}

try {
    Write-Host 'Gemini Video MCP - cai dat tren Windows'
    $codexExecutable = Find-Codex
    if (-not $codexExecutable) {
        throw 'Khong tim thay Codex. Cai va mo Codex desktop, hoac cai Codex CLI, roi chay lai.'
    }
    $pythonExecutable = Find-Python
    if (-not $pythonExecutable) {
        throw 'Can Python 3.10 tro len. Cai Python tu https://www.python.org/downloads/windows/ (chon Add Python to PATH), roi chay lai.'
    }
    Write-Host ('Da tim thay Python: ' + $pythonExecutable)
    Write-Host ('Da tim thay Codex: ' + $codexExecutable)
    if ($CheckOnly) { Write-Host 'Kiem tra dieu kien: OK'; exit 0 }
    $venvDirectory = Join-Path $PSScriptRoot '.venv'
    $venvPython = Join-Path $venvDirectory 'Scripts\python.exe'
    if (-not (Test-Path -LiteralPath $venvPython)) {
        & $pythonExecutable -m venv $venvDirectory
        if ($LASTEXITCODE -ne 0) { throw 'Khong tao duoc moi truong Python.' }
    }
    & $venvPython -m pip install --disable-pip-version-check -r (Join-Path $PSScriptRoot 'requirements.txt')
    if ($LASTEXITCODE -ne 0) { throw 'Khong cai duoc thu vien. Kiem tra ket noi Internet roi chay lai.' }
    & $venvPython -X utf8 (Join-Path $PSScriptRoot 'Kiem-tra.py')
    if ($LASTEXITCODE -ne 0) { throw 'MCP khong vuot qua kiem tra khoi dong.' }
    & $codexExecutable mcp add gemini-video -- $venvPython -X utf8 (Join-Path $PSScriptRoot 'server.py')
    if ($LASTEXITCODE -ne 0) { throw 'Khong dang ky duoc MCP voi Codex.' }
    Write-Host ''
    Write-Host 'CAI DAT THANH CONG.' -ForegroundColor Green
    Write-Host 'Chay Nhap-API.cmd de nhap key tren may nay, sau do dong va mo lai Codex.'
    Write-Host 'Giu nguyen thu muc nay; neu chuyen thu muc, chay lai Cai-dat.cmd.'
} catch {
    Write-Host ('LOI: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
