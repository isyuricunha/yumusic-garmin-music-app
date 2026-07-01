# Export-Release.ps1
# This script temporarily injects the Production UUID into manifest.xml,
# compiles the final .iq file using the local Garmin SDK, and restores the Beta UUID.

$ErrorActionPreference = "Stop"

$BETA_UUID = "cddb60e3-11dc-44b4-845c-13ebc3915f32"
$PUBLIC_UUID = "716a6ef1-f242-4857-ab2d-d6c5c281d994"

$MANIFEST_PATH = "manifest.xml"
$KEY_CACHE = ".developer_key_path"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " YuMusic Garmin Production Exporter" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Check for developer key
$keyPath = ""
if (Test-Path $KEY_CACHE) {
    $keyPath = Get-Content $KEY_CACHE
}

if (-not (Test-Path $keyPath)) {
    Write-Host "Por favor, informe o caminho completo para o seu arquivo developer_key.der:" -ForegroundColor Yellow
    $keyPath = Read-Host "> "
    if (-not (Test-Path $keyPath)) {
        Write-Host "Erro: Arquivo .der não encontrado no caminho fornecido." -ForegroundColor Red
        exit 1
    }
    Set-Content -Path $KEY_CACHE -Value $keyPath
    Write-Host "Caminho da chave salvo para as próximas vezes!" -ForegroundColor Green
}

# 2. Get Garmin SDK Path
$sdkConfigPath = "$env:APPDATA\Garmin\ConnectIQ\current-sdk.cfg"
if (-not (Test-Path $sdkConfigPath)) {
    Write-Host "Erro: SDK do Garmin não encontrado (current-sdk.cfg não existe)." -ForegroundColor Red
    exit 1
}
$sdkPath = Get-Content $sdkConfigPath
$monkeyc = Join-Path $sdkPath "bin\monkeyc.bat"

if (-not (Test-Path $monkeyc)) {
    Write-Host "Erro: monkeyc.bat não encontrado em $monkeyc" -ForegroundColor Red
    exit 1
}

# 3. Swap UUID to Public
Write-Host "Injetando UUID de Producao no manifest..." -ForegroundColor Cyan
$manifestContent = Get-Content $MANIFEST_PATH -Raw
if (-not ($manifestContent -match $BETA_UUID)) {
    if ($manifestContent -match $PUBLIC_UUID) {
        Write-Host "Aviso: O manifest ja parece estar com o UUID Publico." -ForegroundColor Yellow
    } else {
        Write-Host "Erro: Nao encontrei o UUID Beta no manifest.xml para poder substituir." -ForegroundColor Red
        exit 1
    }
} else {
    $manifestContent = $manifestContent -replace $BETA_UUID, $PUBLIC_UUID
    Set-Content -Path $MANIFEST_PATH -Value $manifestContent -NoNewline
}

# 4. Compile .iq
Write-Host "Compilando YuMusic-Production.iq..." -ForegroundColor Cyan
if (-not (Test-Path "bin")) {
    New-Item -ItemType Directory -Force -Path "bin" | Out-Null
}

$outputFile = "bin\YuMusic-Production.iq"
try {
    # Run monkeyc
    & $monkeyc -e -y $keyPath -o $outputFile -f monkey.jungle -w
    $buildSuccess = $?
} finally {
    # 5. Restore UUID regardless of success/failure
    Write-Host "Restaurando UUID de Beta no manifest..." -ForegroundColor Cyan
    $manifestContent = Get-Content $MANIFEST_PATH -Raw
    $manifestContent = $manifestContent -replace $PUBLIC_UUID, $BETA_UUID
    Set-Content -Path $MANIFEST_PATH -Value $manifestContent -NoNewline
}

if ($buildSuccess -and (Test-Path $outputFile)) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " SUCESSO! Aplicativo de Producao Gerado." -ForegroundColor Green
    Write-Host " Arquivo: $outputFile" -ForegroundColor Green
    Write-Host " Faca o upload deste arquivo no Dashboard da Garmin." -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
} else {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host " FALHA NO BUILD." -ForegroundColor Red
    Write-Host " Verifique os erros acima." -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    exit 1
}
