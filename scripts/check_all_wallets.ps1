# check_all_wallets.ps1 — Empire quick-launch wrapper
# Pre-fills known wallet addresses from empire roster.
# NEVER hardcode private keys here. Use Raga Vault (~/.raga_key)
#
# Usage: .\check_all_wallets.ps1

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

& "$scriptDir\wallet_balance.ps1" `
  -SolanaWallet  "Dqnq2iLH33WnwdFsQvSkzNWwZDRvDMkHvpT2RXkUGkNb" `
  -BscWallet     "0x9349b6Ef2d8C3a7F1e4B9D05c82aA1f32aaC549" `
  -EthWallet     "0x9349b6Ef2d8C3a7F1e4B9D05c82aA1f32aaC549" `
  -TonWallet     "UQBkgWhgQcSTwTxDHfXzS7vZl2AGBI83TgZxyX_kRov0_sZ1" `
  -ExportCsv
