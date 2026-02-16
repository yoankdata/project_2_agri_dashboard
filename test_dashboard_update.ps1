$username = "admin@agri.com"
$password = "Password123!"
$baseUrl = "http://localhost:3000/api"

$session = Invoke-RestMethod -Uri "$baseUrl/session" -Method Post -Body (@{ username = $username; password = $password } | ConvertTo-Json) -ContentType "application/json"
$headers = @{ "X-Metabase-Session" = $session.id }

$dashId = 2

# Get current dash
$dashBefore = Invoke-RestMethod -Uri "$baseUrl/dashboard/$dashId" -Method Get -Headers $headers
Write-Output "Before: Name='$($dashBefore.name)', Desc='$($dashBefore.description)', Cards=$($dashBefore.ordered_cards.Count)"

# Get a card to add
$cards = Invoke-RestMethod -Uri "$baseUrl/card" -Method Get -Headers $headers
$kpiCard = $cards | Where-Object { $_.name -like "*Global Performance KPIs*" } | Select-Object -First 1

$orderedCards = @(
    @{
        card_id                = $kpiCard.id
        row                    = 0
        col                    = 0
        size_x                 = 18
        size_y                 = 4
        series                 = @()
        visualization_settings = @{}
        parameter_mappings     = @()
    }
)

$payload = @{
    description   = "Updated via API at $(Get-Date)"
    ordered_cards = $orderedCards
}

Write-Output "Updating Dashboard..."
$response = Invoke-RestMethod -Uri "$baseUrl/dashboard/$dashId" -Method Put -Body ($payload | ConvertTo-Json -Depth 10) -ContentType "application/json" -Headers $headers

# Verify
$dashAfter = Invoke-RestMethod -Uri "$baseUrl/dashboard/$dashId" -Method Get -Headers $headers
Write-Output "After: Name='$($dashAfter.name)', Desc='$($dashAfter.description)', Cards=$($dashAfter.ordered_cards.Count)"
