# wallet_balance.ps1 — Rimuru Empire Multi-Chain Balance Checker
# Checks real, transferable balances only. No demo/fake data.
# Compatible: PowerShell 5.1+, PowerShell Core (pwsh), WSL2
#
# Chains: SOL, BSC, ETH, TON, MEWC (Meowcoin), HyperEVM
#
# Usage:
#   pwsh ./scripts/wallet_balance.ps1 \
#     -SolanaWallet "ADDR" \
#     -BscWallet "0xADDR" \
#     -EthWallet "0xADDR" \
#     -TonWallet "UQADDR" \
#     -MewcWallet "MADDR" \
#     -HyperEvmWallet "0xADDR" \
#     [-DecryptVault] [-ExportCsv]

param(
  [string]$SolanaWallet    = "",
  [string]$BscWallet       = "",
  [string]$EthWallet       = "",
  [string]$TonWallet       = "",
  [string]$MewcWallet      = "",
  [string]$HyperEvmWallet  = "",
  [string]$RpcSolana       = "https://api.mainnet-beta.solana.com",
  [string]$RpcBsc          = "https://rpc.ankr.com/bsc",
  [string]$RpcEth          = "https://rpc.ankr.com/eth",
  [string]$RpcHyperEvm     = "https://rpc.hyperliquid.xyz/evm",
  [string]$MewcPool        = "https://mewc.woolypooly.com",
  [string]$RagaKeyPath     = "",
  [switch]$DecryptVault,
  [switch]$ExportCsv
)

# ── RAGA KEY PATH (WSL2 safe) ────────────────────────────────────────────────
if (-not $RagaKeyPath) {
  if ($env:HOME -and (Test-Path "$env:HOME/.raga_key")) {
    $RagaKeyPath = "$env:HOME/.raga_key"
  } elseif (Test-Path "$HOME/.raga_key") {
    $RagaKeyPath = "$HOME/.raga_key"
  } else {
    $RagaKeyPath = "/home/rimuru/.raga_key"
  }
}
Write-Host "Raga key: $RagaKeyPath" -ForegroundColor DarkGray
if (-not (Test-Path $RagaKeyPath)) {
  Write-Warning "~/.raga_key NOT FOUND at: $RagaKeyPath"
  Write-Warning "Fix: openssl rand -base64 32 > $RagaKeyPath && chmod 600 $RagaKeyPath"
}

# ── OPTIONAL VAULT DECRYPT ──────────────────────────────────────────────────
if ($DecryptVault) {
  Write-Host "`nDecrypting Raga Vault backup..." -ForegroundColor Cyan
  $encFile = Join-Path $PSScriptRoot "../backup/vault.enc"
  $outFile = Join-Path $PSScriptRoot "../backup/vault_decrypted.sql"
  if (Test-Path $encFile) {
    $cmd = "openssl enc -d -aes-256-gcm -pbkdf2 -in `"$encFile`" -out `"$outFile`" -pass file:`"$RagaKeyPath`""
    Invoke-Expression $cmd
    if ($LASTEXITCODE -eq 0) { Write-Host "  Decrypted -> $outFile" -ForegroundColor Green }
    else { Write-Warning "  Decrypt failed. Check key: $RagaKeyPath" }
  } else { Write-Warning "  vault.enc not found: $encFile" }
}

# ── HELPERS ─────────────────────────────────────────────────────────────────────
function Hex-ToDecimal($hex) {
  $hex = ($hex -replace '^0x', '').TrimStart('0')
  if ([string]::IsNullOrEmpty($hex)) { return [decimal]0 }
  $result = [decimal]0
  foreach ($char in $hex.ToCharArray()) {
    $result = $result * 16 + [convert]::ToInt32([string]$char, 16)
  }
  return $result
}

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

# ── MEOWCOIN (MEWC) ─────────────────────────────────────────────────────────
# Uses mewc.tokenview.io public explorer API (no key required)
if ($MewcWallet) {
  Write-Host "`nChecking MEWC (Meowcoin)..." -ForegroundColor Cyan
  try {
    $url = "https://mewc.tokenview.io/api/address/balance/$MewcWallet"
    $r = Invoke-RestMethod -Uri $url -TimeoutSec 20
    if ($r -and $r.data -ne $null) {
      $mewc = [math]::Round([decimal]$r.data, 8)
      Write-Host "  MEWC: $mewc" -ForegroundColor Green
      $rows += [pscustomobject]@{ Chain='MEWC'; Wallet=$MewcWallet; Balance=$mewc; Unit='MEWC'; Timestamp=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
    } else {
      # Fallback: woolypooly miner stats (shows unpaid balance for your worker)
      Write-Warning "  MEWC tokenview failed, trying pool stats..."
      $poolUrl = "https://mewc.woolypooly.com/api/v2/wallets/$MewcWallet"
      $p = Invoke-RestMethod -Uri $poolUrl -TimeoutSec 20
      if ($p -and $p.balance -ne $null) {
        $mewc = [math]::Round([decimal]$p.balance, 8)
        Write-Host "  MEWC (pool unpaid): $mewc" -ForegroundColor Yellow
        $rows += [pscustomobject]@{ Chain='MEWC(pool)'; Wallet=$MewcWallet; Balance=$mewc; Unit='MEWC'; Timestamp=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
      } else { Write-Warning "  MEWC: both explorer and pool API returned no data" }
    }
  } catch { Write-Warning "  MEWC: $_" }
}

# ── HYPEREVM (HyperLiquid L1, Chain ID 999) ───────────────────────────────
if ($HyperEvmWallet) {
  Write-Host "`nChecking HyperEVM..." -ForegroundColor Cyan
  $r = Get-JsonRpc $RpcHyperEvm "eth_getBalance" @($HyperEvmWallet, "latest")
  if ($r -and $r.result) {
    $hype = [math]::Round((Hex-ToDecimal $r.result) / 1e18, 9)
    Write-Host "  HYPE: $hype" -ForegroundColor Green
    $rows += [pscustomobject]@{ Chain='HyperEVM'; Wallet=$HyperEvmWallet; Balance=$hype; Unit='HYPE'; Timestamp=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
  } else { Write-Warning "  HyperEVM: no result" }
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
  Write-Host "Usage: pwsh ./scripts/wallet_balance.ps1 -SolanaWallet 'ADDR' -MewcWallet 'MADDR' -HyperEvmWallet '0xADDR' [-ExportCsv]"
}
