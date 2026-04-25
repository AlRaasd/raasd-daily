# ======================================================
# رفع test-archive.json إلى GitHub
# شغّل هذا الملف في PowerShell:
#   .\upload_test_archive.ps1
# ======================================================

$TOKEN = Read-Host "أدخل GitHub Personal Access Token"

$FILE = "$PSScriptRoot\reports-archive\test-archive.json"
$OWNER = "AlRaasd"
$REPO  = "raasd-daily"
$PATH  = "reports-archive/test-archive.json"

if (-not (Test-Path $FILE)) {
    Write-Host "❌ الملف غير موجود: $FILE" -ForegroundColor Red
    exit 1
}

$bytes   = [System.IO.File]::ReadAllBytes($FILE)
$encoded = [Convert]::ToBase64String($bytes)

$headers = @{
    Authorization  = "token $TOKEN"
    "Content-Type" = "application/json"
    "User-Agent"   = "PowerShell"
}

# Check if file already exists (to get its SHA for update)
$sha = $null
try {
    $existing = Invoke-RestMethod -Uri "https://api.github.com/repos/$OWNER/$REPO/contents/$PATH" `
        -Headers $headers -Method Get -ErrorAction Stop
    $sha = $existing.sha
    Write-Host "📝 الملف موجود مسبقاً — سيتم تحديثه" -ForegroundColor Yellow
} catch {
    Write-Host "📄 الملف جديد — سيتم رفعه لأول مرة" -ForegroundColor Cyan
}

$bodyObj = @{ message = "Add test-archive.json for pilot testing"; content = $encoded }
if ($sha) { $bodyObj.sha = $sha }
$body = $bodyObj | ConvertTo-Json -Depth 3

try {
    $result = Invoke-RestMethod -Uri "https://api.github.com/repos/$OWNER/$REPO/contents/$PATH" `
        -Method Put -Headers $headers -Body $body -ErrorAction Stop
    Write-Host "✅ تم الرفع بنجاح!" -ForegroundColor Green
    Write-Host "   الرابط: $($result.content.html_url)"
} catch {
    Write-Host "❌ فشل الرفع: $_" -ForegroundColor Red
}
