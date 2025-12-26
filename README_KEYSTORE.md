# QuoteSpace Android 출시 모드 빌드 가이드

## 키스토어 생성 방법

### 방법 1: PowerShell 스크립트 사용 (권장)

```powershell
cd android
.\create_keystore.ps1
```

스크립트가 키스토어와 `key.properties` 파일을 자동으로 생성합니다.

### 방법 2: 수동으로 키스토어 생성

1. **키스토어 생성:**
```powershell
cd android/app
keytool -genkey -v -keystore quotespace-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias quotespace
```

2. **key.properties 파일 생성:**
`android/key.properties` 파일을 생성하고 다음 내용을 입력:

```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=quotespace
storeFile=app/quotespace-keystore.jks
```

## 출시 모드 AAB 빌드

키스토어가 생성되면 다음 명령어로 빌드:

```bash
flutter build appbundle --release
```

빌드된 AAB 파일 위치:
- `build/app/outputs/bundle/release/app-release.aab`

## 주의사항

1. **키스토어 파일 보안:**
   - `*.jks`, `*.keystore`, `key.properties` 파일은 `.gitignore`에 추가되어 있습니다
   - 절대 Git에 커밋하지 마세요!
   - 키스토어 파일을 안전한 곳에 백업하세요

2. **키스토어 비밀번호:**
   - 키스토어 비밀번호를 잊어버리면 앱 업데이트가 불가능합니다
   - 반드시 안전한 곳에 기록해두세요

3. **CodeMagic 사용 시:**
   - CodeMagic에서는 환경 변수로 키스토어를 설정할 수 있습니다
   - 로컬 빌드와 CodeMagic 빌드는 서로 다른 키스토어를 사용할 수 있습니다


