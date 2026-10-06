$ErrorActionPreference = 'Stop'
try {
    Write-Host 'Nhap Gemini API key (ky tu se duoc an). Khong dan key vao chat.'
    $geminiSecret = Read-Host 'Gemini API key' -AsSecureString
    if ($geminiSecret.Length -eq 0) { throw 'API key khong duoc de trong.' }
    $secretDirectory = Join-Path $PSScriptRoot '.secrets'
    New-Item -ItemType Directory -Force -Path $secretDirectory | Out-Null
    $geminiSecret | Export-Clixml -LiteralPath (Join-Path $secretDirectory 'gemini-key.xml')
    Write-Host 'Da luu key duoc ma hoa bang tai khoan Windows nay.'
    Write-Host 'Quay lai Codex va nhan: Toi da nhap key, hay kiem tra ket noi Gemini.'
} catch {
    Write-Host ('Loi: ' + $_.Exception.Message)
} finally {
    Read-Host 'Nhan Enter de dong' | Out-Null
}
