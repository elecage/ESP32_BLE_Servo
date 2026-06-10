<#
  ESP32-C3 BLE Servo — Windows 개발환경 설치 스크립트 (PowerShell)
  ----------------------------------------------------------------------
  하는 일:
    1. Python 3 존재 확인 (없으면 안내 후 종료)
    2. 프로젝트 로컬 가상환경 .venv 생성 (시스템 Python 오염 방지)
    3. .venv 안에 PlatformIO Core(pio) 를 pip로 설치
    4. (옵션) 프로젝트 빌드

  실행:
    PowerShell 에서 프로젝트 루트로 이동 후
      Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
      .\scripts\setup_windows.ps1
    빌드까지 한 번에:  .\scripts\setup_windows.ps1 -Build

  설치 후 사용:
    .\.venv\Scripts\pio.exe run            # 직접 호출, 또는
    .\.venv\Scripts\Activate.ps1           # 활성화 후 'pio run'

  ESP32-C3 Super Mini는 네이티브 USB라 별도 드라이버가 보통 필요 없다.
  (구형 CP2102/CH340 보드라면 해당 드라이버를 따로 설치)
#>
param(
    [switch]$Build
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$VenvDir     = Join-Path $ProjectRoot ".venv"
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

# 2) 가상환경(.venv) 생성
$VenvPy = Join-Path $VenvDir "Scripts\python.exe"
if (Test-Path $VenvPy) {
    Write-Host "==> 가상환경 이미 존재: $VenvDir" -ForegroundColor Green
} else {
    Write-Host "==> 가상환경 생성: $VenvDir" -ForegroundColor Cyan
    & $py -m venv $VenvDir
    if (-not (Test-Path $VenvPy)) {
        Write-Host "[!] .venv 생성 실패. python -m venv 가 동작하는지 확인하세요." -ForegroundColor Red
        exit 1
    }
}

# 3) .venv 안에 PlatformIO 설치
Write-Host "==> pip / PlatformIO 설치(업데이트) 중..." -ForegroundColor Cyan
& $VenvPy -m pip install --upgrade pip | Out-Null
& $VenvPy -m pip install --upgrade platformio
$Pio = Join-Path $VenvDir "Scripts\pio.exe"
if (-not (Test-Path $Pio)) {
    Write-Host "[!] 설치 후에도 pio.exe 를 찾지 못했습니다. 로그를 확인하세요." -ForegroundColor Red
    exit 1
}
Write-Host "==> 설치 완료: $Pio ($(& $Pio --version))" -ForegroundColor Green

# 4) 옵션 빌드
if ($Build) {
    Write-Host "`n==> 프로젝트 빌드 (의존성 다운로드 포함)..." -ForegroundColor Cyan
    Push-Location $ProjectRoot
    & $Pio run
    Pop-Location
}

Write-Host ""
Write-Host "완료. 다음 단계:" -ForegroundColor Green
Write-Host "  (활성화) .\.venv\Scripts\Activate.ps1   이후 'pio ...' 로 사용"
Write-Host "  또는 직접 호출:"
Write-Host "    .\.venv\Scripts\pio.exe run -t upload            # 빌드+업로드"
Write-Host "    .\.venv\Scripts\pio.exe device monitor -b 115200 # 시리얼 모니터"
