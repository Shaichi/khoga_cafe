param (
    [Parameter(Mandatory=$true)]
    [string]$orderId
)

$reference = "KHOGA-$orderId"
$payload = "$orderId|$reference"
$secret = "dev-webhook-secret"

# Generate HMAC-SHA256 signature
$hmac = New-Object System.Security.Cryptography.HMACSHA256
$hmac.Key = [Text.Encoding]::UTF8.GetBytes($secret)
$signatureBytes = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($payload))
$signature = [Convert]::ToBase64String($signatureBytes)

$body = @{
    orderId = $orderId
    reference = $reference
    transactionId = "TXN-DEMO-$(Get-Random -Minimum 1000 -Maximum 9999)"
} | ConvertTo-Json

Write-Host "Sending mock VietQR webhook for Order: $orderId" -ForegroundColor Cyan

Try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/payments/vietqr/callback" `
        -Method Post `
        -Headers @{ "x-api-validate" = $signature; "Content-Type" = "application/json" } `
        -Body $body
        
    Write-Host "Success! System response:" -ForegroundColor Green
    $response | ConvertTo-Json | Write-Host
} Catch {
    Write-Host "Error sending webhook: $_" -ForegroundColor Red
}
