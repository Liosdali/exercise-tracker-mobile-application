# Atlas Workout — teshis ciktisi toplayici
#
# Kullanim:  .\claude-check.ps1
#
# Ciktilari claude-out\ altina yazar. Claude o klasoru dogrudan okuyabiliyor,
# boylece terminal ciktisini kopyalayip yapistirmaya gerek kalmiyor.
# Kimlik bilgisi yazmaz; .env'e dokunmaz.

$ErrorActionPreference = 'Continue'
$out = Join-Path $PSScriptRoot 'claude-out'
New-Item -ItemType Directory -Force -Path $out | Out-Null

function Kaydet($ad, $komut) {
    $yol = Join-Path $out "$ad.txt"
    Write-Host "-> $ad" -ForegroundColor Cyan
    "=== $komut ==="                         | Out-File -FilePath $yol -Encoding utf8
    "=== $(Get-Date -Format o) ==="          | Out-File -FilePath $yol -Encoding utf8 -Append
    ""                                        | Out-File -FilePath $yol -Encoding utf8 -Append
    try {
        Invoke-Expression "$komut 2>&1" | Out-File -FilePath $yol -Encoding utf8 -Append
        "" | Out-File -FilePath $yol -Encoding utf8 -Append
        "=== cikis kodu: $LASTEXITCODE ===" | Out-File -FilePath $yol -Encoding utf8 -Append
    } catch {
        "=== KOMUT CALISTIRILAMADI: $_ ===" | Out-File -FilePath $yol -Encoding utf8 -Append
    }
}

Kaydet 'flutter-analyze'   'flutter analyze'
Kaydet 'flutter-test'      'flutter test --reporter expanded'
Kaydet 'migration-list'    'supabase migration list'
Kaydet 'flutter-doctor'    'flutter doctor -v'

Write-Host ""
Write-Host "Bitti. Ciktilar: $out" -ForegroundColor Green
Write-Host "Claude'a 'ciktilar hazir' demen yeterli." -ForegroundColor Green
