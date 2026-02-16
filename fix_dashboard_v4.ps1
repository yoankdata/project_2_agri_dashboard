$username = "admin@agri.com"
$password = "Password123!"
$baseUrl = "http://localhost:3000/api"

$session = Invoke-RestMethod -Uri "$baseUrl/session" -Method Post -Body (@{ username = $username; password = $password } | ConvertTo-Json) -ContentType "application/json"
$headers = @{ "X-Metabase-Session" = $session.id }

# Get Dash
$dashes = Invoke-RestMethod -Uri "$baseUrl/dashboard" -Method Get -Headers $headers
$dash = $dashes | Where-Object { $_.name -eq "Agri Intelligence V1" }
$dashId = $dash.id
Write-Output "Target Dashboard ID: $dashId"

# Get Cards
$cards = Invoke-RestMethod -Uri "$baseUrl/card" -Method Get -Headers $headers
$kpiCard = $cards | Where-Object { $_.name -like "*Global Performance KPIs*" } | Select-Object -First 1
$volCard = $cards | Where-Object { $_.name -like "*Volatility*" } | Select-Object -First 1
$logCard = $cards | Where-Object { $_.name -like "*Logistics*" } | Select-Object -First 1
$qualCard = $cards | Where-Object { $_.name -like "*Data Quality*" } | Select-Object -First 1

# Construct ordered_cards array
# Note: visualization_settings must be empty objects, not null, for safety
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
    },
    @{
        card_id                = $volCard.id
        row                    = 4
        col                    = 0
        size_x                 = 9
        size_y                 = 8
        series                 = @()
        visualization_settings = @{}
        parameter_mappings     = @()
    },
    @{
        card_id                = $logCard.id
        row                    = 4
        col                    = 9
        size_x                 = 9
        size_y                 = 8
        series                 = @()
        visualization_settings = @{}
        parameter_mappings     = @()
    },
    @{
        card_id                = $qualCard.id
        row                    = 12
        col                    = 0
        size_x                 = 18
        size_y                 = 6
        series                 = @()
        visualization_settings = @{}
        parameter_mappings     = @()
    }
)

# Update Dashboard
# We need to send the existing structure but with updated columns
# Usually PUT /api/dashboard/:id accepts properties to update.
# For ordered_cards, we just send it.

$payload = @{
    ordered_cards = $orderedCards
}

Write-Output "Updating Dashboard with $($orderedCards.Count) cards..."
try {
    Invoke-RestMethod -Uri "$baseUrl/dashboard/$dashId" -Method Put -Body ($payload | ConvertTo-Json -Depth 10) -ContentType "application/json" -Headers $headers
    Write-Output "Success!"
}
catch {
    Write-Error "Failed to update dashboard"
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Error $reader.ReadToEnd()
    }
}
