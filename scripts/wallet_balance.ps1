# wallet_balance.ps1 — Rimuru Empire Multi-Chain Balance Checker
# Checks real, transferable balances only. No demo/fake data.
# Part of the Rimuru Empire AI Capsule Series
#
# Usage:
#   .\wallet_balance.ps1 -SolanaWallet "..." -BscWallet "0x..." -TonWallet "UQ..."

param(
  [string]$SolanaWallet  = "",
  [string]$BscWallet     = "",
  [string]$EthWallet     = "",
  [string]$TonWallet     = "",
  [string]$RpcSolana     = "https://api.mainnet-beta.solana.com",
  [string]$RpcBsc        = "https://rpc.ankr.com/bsc",
  [string]$RpcEth        = "https://rpc.ankr.com/eth",
  [switch]$ExportCsv
)

Add-Type -AssemblyName System.Numerics

function Get-JsonRpcResult($Url, $Method, $Params) {
  $body = @{ jsonrpc = "2.0"; id = 1; method = $Method; params = $Params } | ConvertTo-Json -Depth 10
  try {
    return Invoke-RestMethod -Uri $Url -Method Post -ContentType "application/json" -Body $body -TimeoutSec 20
  } catch {
    Write-Warning "RPC call failed: $Url — $_"
    return $null
  }
}

$rows = @()

# --- SOLANA ---
if ($SolanaWallet) {
  Write-Host "`n👁️  Checking Solana..." -ForegroundColor Cyan
  $r = Get-JsonRpcResult $RpcSolana "getBalance" @($SolanaWallet)
  if ($r -and $r.result -ne $null) {
    $sol = [math]::Round(($r.result.value / 1000000000), 9)
    $rows += [pscustomobject]@{ Chain='Solana'; Wallet=$SolanaWallet; Balance=$sol; Unit='SOL'; Source=$RpcSolana; Timestamp=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
    Write-Host "  SOL: $sol" -ForegroundColor Green
  } else {
    Write-Warning "  Solana: no result returned"
  }
}

# --- BSC ---
if ($BscWallet) {
  Write-Host "`n👁️  Checking BSC..." -ForegroundColor Cyan
  $r = Get-JsonRpcResult $RpcBsc "eth_getBalance" @($BscWallet, "latest")
  if ($r -and $r.result) {
    $hex = $r.result.Replace("0x", "")
    if ($hex -eq "" -or $hex -eq "0") {
      $bnb = 0
    } else {
      $wei = [System.Numerics.BigInteger]::Parse("0" + $hex, [System.Globalization.NumberStyles]::HexNumber)
      $bnb = [math]::Round(([decimal]$wei / 1e18), 9)
    }
    $rows += [pscustomobject]@{ Chain='BSC'; Wallet=$BscWallet; Balance=$bnb; Unit='BNB'; Source=$RpcBsc; Timestamp=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
    Write-Host "  BNB: $bnb" -ForegroundColor Green
  } else {
    Write-Warning "  BSC: no result returned"
  }
}

# --- ETH ---
if ($EthWallet) {
  Write-Host "`n👁️  Checking ETH..." -ForegroundColor Cyan
  $r = Get-JsonRpcResult $RpcEth "eth_getBalance" @($EthWallet, "latest")
  if ($r -and $r.result) {
    $hex = $r.result.Replace("0x", "")
    if ($hex -eq "" -or $hex -eq "0") {
      $eth = 0
    } else {
      $wei = [System.Numerics.BigInteger]::Parse("0" + $hex, [System.Globalization.NumberStyles]::HexNumber)
      $eth = [math]::Round(([decimal]$wei / 1e18), 9)
    }
    $rows += [pscustomobject]@{ Chain='ETH'; Wallet=$EthWallet; Balance=$eth; Unit='ETH'; Source=$RpcEth; Timestamp=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
    Write-Host "  ETH: $eth" -ForegroundColor Green
  } else {
    Write-Warning "  ETH: no result returned"
  }
}

# --- TON ---
if ($TonWallet) {
  Write-Host "`n👁️  Checking TON..." -ForegroundColor Cyan
  try {
    $url = "https://toncenter.com/api/v2/getAddressBalance?address=$TonWallet"
    $r = Invoke-RestMethod -Uri $url -TimeoutSec 20
    if ($r.ok -and $r.result -ne $null) {
      $ton = [math]::Round(([decimal]$r.result / 1000000000), 9)
      $rows += [pscustomobject]@{ Chain='TON'; Wallet=$TonWallet; Balance=$ton; Unit='TON'; Source='toncenter.com'; Timestamp=(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') }
      Write-Host "  TON: $ton" -ForegroundColor Green
    }
  } catch {
    Write-Warning "  TON: $_"
  }
}

# --- OUTPUT ---
Write-Host ""
if ($rows.Count -gt 0) {
  Write-Host "========================================" -ForegroundColor Yellow
  Write-Host "  EMPIRE WALLET BALANCES" -ForegroundColor Yellow
  Write-Host "========================================" -ForegroundColor Yellow
  $rows | Format-Table Chain, Wallet, Balance, Unit, Timestamp -AutoSize

  if ($ExportCsv) {
    $outDir = Join-Path $PSScriptRoot "..\output"
    if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
    $outFile = Join-Path $outDir "wallet_balances.csv"
    $rows | Export-Csv -Path $outFile -NoTypeInformation -Encoding UTF8
    Write-Host "✅ Exported to $outFile" -ForegroundColor Green
  }
} else {
  Write-Host "⚠️  No wallet addresses provided or no balances returned." -ForegroundColor Red
  Write-Host "Usage: .\wallet_balance.ps1 -SolanaWallet '...' -BscWallet '0x...' -TonWallet 'UQ...' [-ExportCsv]"
}
