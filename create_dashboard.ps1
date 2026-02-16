$username = "admin@agri.com"
$password = "Password123!"
$baseUrl = "http://localhost:3000/api"

# Login
$session = Invoke-RestMethod -Uri "$baseUrl/session" -Method Post -Body (@{ username = $username; password = $password } | ConvertTo-Json) -ContentType "application/json"
$headers = @{ "X-Metabase-Session" = $session.id }

# Table IDs
$tableIds = Get-Content "table_ids.json" | ConvertFrom-Json

# 1. Create Collection (Optional, putting in "Our analytics")
# We'll just put it in the root collection or "Our analytics" (usually ID 1)

# 2. Create Cards (Questions)
function Create-Card {
    param ($name, $tableId, $display)
    $card = @{
        name                   = $name
        dataset_query          = @{
            database = 2  # Agri DWH ID
            type     = "query"
            query    = @{
                "source-table" = $tableId
            }
        }
        display                = $display
        visualization_settings = @{}
    }
    $response = Invoke-RestMethod -Uri "$baseUrl/card" -Method Post -Body ($card | ConvertTo-Json -Depth 10) -ContentType "application/json" -Headers $headers
    return $response.id
}

Write-Output "Creating Cards..."
$cardIds = @{}
$cardIds["KPIs"] = Create-Card "Global Performance KPIs" $tableIds.kpi_global "table"
$cardIds["Volatility"] = Create-Card "Volatility & Risk Analysis" $tableIds.volatility_analysis "table"
$cardIds["Logistics"] = Create-Card "Logistics & Margin" $tableIds.logistics_margin "table"
$cardIds["DataQuality"] = Create-Card "Data Quality Metrics" $tableIds.data_quality_metrics "table"

Write-Output "Card IDs: $($cardIds | ConvertTo-Json)"

# 3. Create Dashboard
$dashboard = @{
    name        = "Agri Intelligence V1"
    description = "Vue 360 de la performance agricole"
    parameters  = @(
        @{
            name = "Region"
            slug = "region"
            id   = "parameter_region"
            type = "category"
        },
        @{
            name = "Crop"
            slug = "crop"
            id   = "parameter_crop"
            type = "category"
        }
    )
}

Write-Output "Creating Dashboard..."
$dashResponse = Invoke-RestMethod -Uri "$baseUrl/dashboard" -Method Post -Body ($dashboard | ConvertTo-Json -Depth 10) -ContentType "application/json" -Headers $headers
$dashId = $dashResponse.id
Write-Output "Dashboard ID: $dashId"

# 4. Add Cards to Dashboard
# Grid size is usually 18 columns.
# We want 4 tiles. Let's arrange them 2x2.

function Add-Card-To-Dash {
    param ($dashId, $cardId, $x, $y, $w, $h)
    $dashCard = @{
        cardId                 = $cardId
        row                    = $y
        col                    = $x
        size_x                 = $w
        size_y                 = $h
        visualization_settings = @{}
        parameter_mappings     = @()  # Filters would need complex mapping here
    }
    Invoke-RestMethod -Uri "$baseUrl/dashboard/$dashId/cards" -Method Post -Body ($dashCard | ConvertTo-Json -Depth 10) -ContentType "application/json" -Headers $headers
}

Add-Card-To-Dash $dashId $cardIds["KPIs"] 0 0 18 4
Add-Card-To-Dash $dashId $cardIds["Volatility"] 0 4 9 8
Add-Card-To-Dash $dashId $cardIds["Logistics"] 9 4 9 8
Add-Card-To-Dash $dashId $cardIds["DataQuality"] 0 12 18 6

Write-Output "Dashboard created successfully!"
