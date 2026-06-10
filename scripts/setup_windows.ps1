<#
  ESP32-C3 BLE Servo — Windows 개발환경 설치 스크립트 (PowerShell)
  ----------------------------------------------------------------------
  하는 일:
    1. Python 3 존재 확인 (없으면 안내 후 종료)
    2. PlatformIO Core(pio) 설치 (공식 get-platformio.py 사용)
    3. PATH 안내
    4. 의존성 받기 위해 프로젝트 1회 빌드 (옵션)

  실행:
    PowerShell 에서 프로젝트 루트로 이동 후
      Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
      .\scripts\setup_windows.ps1
    빌드까지 한 번에:  .\scripts\setup_windows.ps1 -Build

  ESP32-C3 Super Mini는 네이티브 USB라 별도 드라이버가 보통 필요 없다.
  (구형 CP2102/CH340 보드라면 해당 드라이버를 따로 설치)
#>
param(
    [switch]$Build
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
Write-Host "==> Project root: $ProjectRoot" -ForegroundColor Cyan

# 1) Python 확인
function Get-PythonCmd {
    foreach ($c in @("python", "python3", "py")) {
        $p = Get-Command $c -ErrorAction SilentlyContinue
        if ($p) {
            try {
                $v = & $c --version 2>&1
                if ($v -match "Python 3") { return $c }
            } catch {}
        }
    }
    return $null
}

$py = Get-PythonCmd
if (-not $py) {
    Write-Host "[!] Python 3 를 찾을 수 없습니다." -ForegroundColor Red
    Write-Host "    https://www.python.org/downloads/ 에서 설치하거나," -ForegroundColor Yellow
    Write-Host "    'winget install Python.Python.3.12' 실행 후 다시 시도하세요." -ForegroundColor Yellow
    exit 1
}
Write-Host "==> Using Python: $py ($(& $py --version))" -ForegroundColor Green

# 2) PlatformIO Core 설치
$pioCandidate = Join-Path $env:USERPROFILE ".platformio\penv\Scripts\pio.exe"
if (Test-Path $pioCandidate) {
    Write-Host "==> PlatformIO 이미 설치됨: $pioCandidate" -ForegroundColor Green
    $pio = $pioCandidate
} else {
    Write-Host "==> PlatformIO Core 설치 중..." -ForegroundColor Cyan
    $installer = Join-Path $env:TEMP "get-platformio.py"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py" -OutFile $installer
    & $py $installer
    if (-not (Test-Path $pioCandidate)) {
        Write-Host "[!] 설치 후에도 pio.exe 를 찾지 못했습니다. 로그를 확인하세요." -ForegroundColor Red
        exit 1
    }
    $pio = $pioCandidate
    Write-Host "==> 설치 완료: $pio" -ForegroundColor Green
}

# 3) PATH 안내
$pioBin = Split-Path -Parent $pio
Write-Host ""
Write-Host "다음 폴더를 PATH 에 추가하면 'pio' 를 어디서나 쓸 수 있습니다:" -ForegroundColor Yellow
Write-Host "    $pioBin" -ForegroundColor Yellow
Write-Host '  (영구 추가) setx PATH "$env:PATH;'"$pioBin"'"' -ForegroundColor DarkGray

# 4) 옵션 빌드
if ($Build) {
    Write-Host "`n==> 프로젝트 빌드 (의존성 다운로드 포함)..." -ForegroundColor Cyan
    Push-Location $ProjectRoot
    & $pio run
    Pop-Location
}

Write-Host ""
Write-Host "완료. 다음 단계:" -ForegroundColor Green
Write-Host "  보드 연결 후 빌드+업로드:  & '$pio' run -t upload"
Write-Host "  시리얼 모니터:             & '$pio' device monitor -b 115200"
