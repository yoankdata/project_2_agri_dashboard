$username = "admin@agri.com"
$password = "Password123!"
$baseUrl = "http://localhost:3000/api"

$session = Invoke-RestMethod -Uri "$baseUrl/session" -Method Post -Body (@{ username = $username; password = $password } | ConvertTo-Json) -ContentType "application/json"
$headers = @{ "X-Metabase-Session" = $session.id }

# Get Dash ID
$dash = (Invoke-RestMethod -Uri "$baseUrl/dashboard" -Method Get -Headers $headers) | Where-Object { $_.name -eq "Agri Intelligence V1" }
$dashId = $dash.id
Write-Output "Target Dashboard ID: $dashId"

# Get Card IDs
$cards = Invoke-RestMethod -Uri "$baseUrl/card" -Method Get -Headers $headers
$kpiCard = $cards | Where-Object { $_.name -like "*Global Performance KPIs*" } | Select-Object -First 1
$volatilityCard = $cards | Where-Object { $_.name -like "*Volatility*" } | Select-Object -First 1
$logisticsCard = $cards | Where-Object { $_.name -like "*Logistics*" } | Select-Object -First 1
$qualityCard = $cards | Where-Object { $_.name -like "*Data Quality*" } | Select-Object -First 1

Write-Output "KPI Card: $($kpiCard.id)"
Write-Output "Volatility Card: $($volatilityCard.id)"
Write-Output "Logistics Card: $($logisticsCard.id)"
Write-Output "Quality Card: $($qualityCard.id)"

function AddCard ($dId, $cId, $row, $col, $sx, $sy) {
    if (-not $cId) { Write-Warning "Skipping null card ID"; return }
    
    $body = @{
        cardId = $cId
        row    = $row
        col    = $col
        size_x = $sx
        size_y = $sy
    }
    
    Write-Output "Adding Card $cId to Dash $dId..."
    try {
        Invoke-RestMethod -Uri "$baseUrl/dashboard/$dId/cards" -Method Post -Body ($body | ConvertTo-Json) -ContentType "application/json" -Headers $headers
        Write-Output "Success."
    }
    catch {
        Write-Error "Failed to add card $cId"
        # Print inner exception response if available
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            if ($stream) {
                $reader = New-Object System.IO.StreamReader($stream)
                Write-Error $reader.ReadToEnd()
            }
        }
    }
}

AddCard $dashId $kpiCard.id 0 0 18 4
AddCard $dashId $volatilityCard.id 4 0 9 6  # Row 4, Col 0
AddCard $dashId $logisticsCard.id 4 9 9 6   # Row 4, Col 9
AddCard $dashId $qualityCard.id 10 0 18 6   # Row 10, Col 0
