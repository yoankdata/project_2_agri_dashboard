$username = "admin@agri.com"
$password = "Password123!"
$baseUrl = "http://localhost:3000/api"

$session = Invoke-RestMethod -Uri "$baseUrl/session" -Method Post -Body (@{ username = $username; password = $password } | ConvertTo-Json) -ContentType "application/json"
$headers = @{ "X-Metabase-Session" = $session.id }

$dashId = 2

# Get Cards
$cards = Invoke-RestMethod -Uri "$baseUrl/card" -Method Get -Headers $headers
$kpiCard = $cards | Where-Object { $_.name -like "*Global Performance KPIs*" } | Select-Object -First 1
$volCard = $cards | Where-Object { $_.name -like "*Volatility*" } | Select-Object -First 1
$logCard = $cards | Where-Object { $_.name -like "*Logistics*" } | Select-Object -First 1
$qualCard = $cards | Where-Object { $_.name -like "*Data Quality*" } | Select-Object -First 1

# Updated structure with camelCase keys
$orderedCards = @(
    @{
        cardId                 = $kpiCard.id
        row                    = 0
        col                    = 0
        sizeX                  = 18
        sizeY                  = 4
        series                 = @()
        visualization_settings = @{}
        parameter_mappings     = @()
    },
    @{
        cardId                 = $volCard.id
        row                    = 4
        col                    = 0
        sizeX                  = 9
        sizeY                  = 8
        series                 = @()
        visualization_settings = @{}
        parameter_mappings     = @()
    },
    @{
        cardId                 = $logCard.id
        row                    = 4
        col                    = 9
        sizeX                  = 9
        sizeY                  = 8
        series                 = @()
        visualization_settings = @{}
        parameter_mappings     = @()
    },
    @{
        cardId                 = $qualCard.id
        row                    = 12
        col                    = 0
        sizeX                  = 18
        sizeY                  = 6
        series                 = @()
        visualization_settings = @{}
        parameter_mappings     = @()
    }
)

$payload = @{
    ordered_cards = $orderedCards
}

Write-Output "Updating Dashboard (CamelCase)..."
Invoke-RestMethod -Uri "$baseUrl/dashboard/$dashId" -Method Put -Body ($payload | ConvertTo-Json -Depth 10) -ContentType "application/json" -Headers $headers

# Verify
$dashAfter = Invoke-RestMethod -Uri "$baseUrl/dashboard/$dashId" -Method Get -Headers $headers
Write-Output "After: Cards=$($dashAfter.ordered_cards.Count)"
