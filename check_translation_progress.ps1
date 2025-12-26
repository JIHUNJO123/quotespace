# 번역 진행 상황 확인 스크립트
Write-Host "=== 번역 진행 상황 ===" -ForegroundColor Cyan

if (Test-Path "assets\translation_progress.txt") {
    Write-Host "`n진행 상황:" -ForegroundColor Yellow
    Get-Content "assets\translation_progress.txt"
} else {
    Write-Host "진행 파일이 없습니다. 번역 스크립트가 아직 시작되지 않았을 수 있습니다." -ForegroundColor Yellow
}

Write-Host "`n=== 번역 파일 상태 ===" -ForegroundColor Cyan
if (Test-Path "assets\quotes_translations.json") {
    $file = Get-Item "assets\quotes_translations.json"
    $sizeMB = [math]::Round($file.Length/1MB, 2)
    Write-Host "번역 파일 존재: $sizeMB MB" -ForegroundColor Green
    Write-Host "마지막 수정: $($file.LastWriteTime)" -ForegroundColor Green
    
    try {
        python -c "import json; data=json.load(open('assets/quotes_translations.json', 'r', encoding='utf-8')); print(f'번역된 명언 수: {len(data)}'); sample=list(data.values())[0] if data else {}; langs=list(sample.get('translations', {}).keys()); print(f'번역 언어: {langs}')"
    } catch {
        Write-Host "번역 파일 읽기 실패" -ForegroundColor Red
    }
} else {
    Write-Host "번역 파일이 아직 생성되지 않았습니다." -ForegroundColor Red
}

Write-Host "`n=== Python 프로세스 ===" -ForegroundColor Cyan
$pythonProcs = Get-Process python -ErrorAction SilentlyContinue
if ($pythonProcs) {
    Write-Host "실행 중인 Python 프로세스: $($pythonProcs.Count)개" -ForegroundColor Green
    $pythonProcs | ForEach-Object {
        $runtime = (Get-Date) - $_.StartTime
        Write-Host "  PID: $($_.Id), 실행 시간: $($runtime.ToString('hh\:mm\:ss'))"
    }
} else {
    Write-Host "실행 중인 Python 프로세스가 없습니다." -ForegroundColor Yellow
}

