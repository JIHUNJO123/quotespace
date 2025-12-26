# 키스토어 생성 스크립트
Write-Host "=== QuoteSpace 키스토어 생성 ===" -ForegroundColor Cyan
Write-Host ""

$keystorePath = "app\quotespace-keystore.jks"

if (Test-Path $keystorePath) {
    Write-Host "키스토어가 이미 존재합니다: $keystorePath" -ForegroundColor Yellow
    $overwrite = Read-Host "덮어쓰시겠습니까? (y/n)"
    if ($overwrite -ne "y") {
        Write-Host "취소되었습니다." -ForegroundColor Red
        exit
    }
}

Write-Host "키스토어 정보를 입력하세요:" -ForegroundColor Yellow
$storePassword = Read-Host "키스토어 비밀번호" -AsSecureString
$storePasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePassword))

$keyPassword = Read-Host "키 비밀번호 (키스토어 비밀번호와 동일하게 입력)" -AsSecureString
$keyPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPassword))

Write-Host ""
Write-Host "키스토어를 생성하는 중..." -ForegroundColor Cyan

$keytoolCmd = "keytool -genkey -v -keystore $keystorePath -keyalg RSA -keysize 2048 -validity 10000 -alias quotespace -storepass $storePasswordPlain -keypass $keyPasswordPlain -dname `"CN=QuoteSpace, OU=Development, O=JIHUNJO, L=Seoul, ST=Seoul, C=KR`""

Invoke-Expression $keytoolCmd

if (Test-Path $keystorePath) {
    Write-Host ""
    Write-Host "키스토어가 생성되었습니다: $keystorePath" -ForegroundColor Green
    
    # key.properties 파일 생성
    $keyPropertiesPath = "..\key.properties"
    $keyPropertiesContent = @"
storePassword=$storePasswordPlain
keyPassword=$keyPasswordPlain
keyAlias=quotespace
storeFile=app\quotespace-keystore.jks
"@
    
    Set-Content -Path $keyPropertiesPath -Value $keyPropertiesContent -Encoding UTF8
    Write-Host "key.properties 파일이 생성되었습니다: $keyPropertiesPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "주의: key.properties 파일은 .gitignore에 추가되어 있어야 합니다!" -ForegroundColor Yellow
} else {
    Write-Host "키스토어 생성에 실패했습니다." -ForegroundColor Red
}

