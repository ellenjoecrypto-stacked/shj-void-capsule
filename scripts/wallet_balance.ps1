# wallet_balance.ps1 — Rimuru Empire Multi-Chain Balance Checker
# Checks real, transferable balances only. No demo/fake data.
# Compatible: PowerShell 5.1+, PowerShell Core (pwsh), WSL2
#
# Usage:
#   pwsh ./scripts/wallet_balance.ps1 -SolanaWallet "ADDR" -BscWallet "0xADDR" [-DecryptVault] [-ExportCsv]
#
# Raga Vault key: ~/.raga_key (WSL2: /home/rimuru/.raga_key)
# Decrypt format: AES-256-GCM via openssl

param(
  [string]$SolanaWallet = "",
  [string]$BscWallet    = "",
  [string]$EthWallet    = "",
  [string]$TonWallet    = "",
  [string]$RpcSolana    = "https://api.mainnet-beta.solana.com",
  [string]$RpcBsc       = "https://rpc.ankr.com/bsc",
  [string]$RpcEth       = "https://rpc.ankr.com/eth",
  [string]$RagaKeyPath  = "",   # auto-detected if empty
  [switch]$DecryptVault,        # run openssl decrypt before balance check
  [switch]$ExportCsv
)

# ── RAGA KEY PATH (WSL2 safe) ────────────────────────────────────────────────
if (-not $RagaKeyPath) {
  # Prefer $env:HOME (correct in WSL2/Linux), fallback to Windows home
  if ($env:HOME -and (Test-Path "$env:HOME/.raga_key")) {
    $RagaKeyPath = "$env:HOME/.raga_key"
  } elseif (Test-Path "$HOME/.raga_key") {
    $RagaKeyPath = "$HOME/.raga_key"
  } else {
    $RagaKeyPath = "/home/rimuru/.raga_key"  # hardcoded WSL2 fallback
  }
}
Write-Host "Raga key path: $RagaKeyPath" -ForegroundColor DarkGray
if (-not (Test-Path $RagaKeyPath)) {
  Write-Warning "~/.raga_key NOT FOUND at: $RagaKeyPath"
  Write-Warning "Create it with: openssl rand -base64 32 > $RagaKeyPath && chmod 600 $RagaKeyPath"
}

# ── OPTIONAL VAULT DECRYPT ───────────────────────────────────────────────────
if ($DecryptVault) {
  Write-Host "`nDecrypting Raga Vault backup..." -ForegroundColor Cyan
  $encFile = Join-Path $PSScriptRoot "../backup/vault.enc"
  $outFile = Join-Path $PSScriptRoot "../backup/vault_decrypted.sql"
  if (Test-Path $encFile) {
    $cmd = "openssl enc -d -aes-256-gcm -pbkdf2 -in `"$encFile`" -out `"$outFile`" -pass file:`"$RagaKeyPath`""
    Write-Host "  Running: $cmd" -ForegroundColor DarkGray
    Invoke-Expression $cmd
    if ($LASTEXITCODE -eq 0) {
      Write-Host "  Vault decrypted -> $outFile" -ForegroundColor Green
    } else {
      Write-Warning "  Decrypt failed. Check key at: $RagaKeyPath"
    }
  } else {
    Write-Warning "  vault.enc not found at: $encFile"
  }
}

# ── HEX TO DECIMAL (no BigInteger, pure PS math) ─────────────────────────────
function Hex-ToDecimal($hex) {
  $hex = ($hex -replace '^0x', '').TrimStart('0')
  if ([string]::IsNullOrEmpty($hex)) { return [decimal]0 }
  $result = [decimal]0
  foreach ($char in $hex.ToCharArray()) {
    $result = $result * 16 + [convert]::ToInt32([string]$char, 16)
  }
  return $result
}

# ── JSON-RPC HELPER ───────────────────────────────────────────────────────────
function Get-JsonRpc($Url, $Method, $Params) {
  $body = @{ jsonrpc = "2.0"; id = 1; method = $Method; params = $Params } | ConvertTo-Json -Depth 10
  try {
    return Invoke-RestMethod -Uri $Url -Method Post -ContentType "application/json" -Body $body -TimeoutSec 20
  } catch {
    Write-Warning "RPC failed [$Url]: $_"
    return $null
  }
}

$rows = @()

# ── SOLANA ────────────────────────────────────────────────────────────────────
if ($SolanaWallet) {
  Write-Host "`nChecking Solana..." -ForegroundColor Cyan
  $r = Get-JsonRpc $RpcSolana "getBalance" @($SolanaWallet)
  if ($r -and $r.PSObject.Properties['result'] -and $r.result -ne $null) {
    $lamports = if ($r.result.PSObject.Properties['value']) { $r.result.value } else { $r.result }
    $sol = [math]::Round(([decimal]$lamports / 1000000000), 9)
    Write-Host "  SOL: $sol" -ForegroundColor Green
    $rows += [pscustomobject]@{ Chain='Solana'; Wallet=$SolanaWallet; Balance=$sol; Unit='SOL'; Timestamp=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
  } else { Write-Warning "  Solana: no result" }
}

# ── BSC ───────────────────────────────────────────────────────────────────────
if ($BscWallet) {
  Write-Host "`nChecking BSC..." -ForegroundColor Cyan
  $r = Get-JsonRpc $RpcBsc "eth_getBalance" @($BscWallet, "latest")
  if ($r -and $r.result) {
    $bnb = [math]::Round((Hex-ToDecimal $r.result) / 1e18, 9)
    Write-Host "  BNB: $bnb" -ForegroundColor Green
    $rows += [pscustomobject]@{ Chain='BSC'; Wallet=$BscWallet; Balance=$bnb; Unit='BNB'; Timestamp=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
  } else { Write-Warning "  BSC: no result" }
}

# ── ETH ───────────────────────────────────────────────────────────────────────
if ($EthWallet) {
  Write-Host "`nChecking ETH..." -ForegroundColor Cyan
  $r = Get-JsonRpc $RpcEth "eth_getBalance" @($EthWallet, "latest")
  if ($r -and $r.result) {
    $eth = [math]::Round((Hex-ToDecimal $r.result) / 1e18, 9)
    Write-Host "  ETH: $eth" -ForegroundColor Green
    $rows += [pscustomobject]@{ Chain='ETH'; Wallet=$EthWallet; Balance=$eth; Unit='ETH'; Timestamp=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
  } else { Write-Warning "  ETH: no result" }
}

# ── TON ───────────────────────────────────────────────────────────────────────
if ($TonWallet) {
  Write-Host "`nChecking TON..." -ForegroundColor Cyan
  try {
    $r = Invoke-RestMethod -Uri "https://toncenter.com/api/v2/getAddressBalance?address=$TonWallet" -TimeoutSec 20
    if ($r.ok -and $r.result -ne $null) {
      $ton = [math]::Round(([decimal]$r.result / 1000000000), 9)
      Write-Host "  TON: $ton" -ForegroundColor Green
      $rows += [pscustomobject]@{ Chain='TON'; Wallet=$TonWallet; Balance=$ton; Unit='TON'; Timestamp=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
    }
  } catch { Write-Warning "  TON: $_" }
}

# ── OUTPUT ────────────────────────────────────────────────────────────────────
Write-Host ""
if ($rows.Count -gt 0) {
  Write-Host "======================================" -ForegroundColor Yellow
  Write-Host "   EMPIRE WALLET BALANCES" -ForegroundColor Yellow
  Write-Host "======================================" -ForegroundColor Yellow
  $rows | Format-Table Chain, Wallet, Balance, Unit, Timestamp -AutoSize

  if ($ExportCsv) {
    $outDir = Join-Path $PSScriptRoot "../output"
    if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
    $outFile = Join-Path $outDir "wallet_balances.csv"
    $rows | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8
    Write-Host "Exported -> $outFile" -ForegroundColor Green
  }
} else {
  Write-Host "No wallets provided or all RPCs failed." -ForegroundColor Red
  Write-Host "Usage: pwsh ./scripts/wallet_balance.ps1 -SolanaWallet 'ADDR' -BscWallet '0xADDR' [-DecryptVault] [-ExportCsv]"
}
