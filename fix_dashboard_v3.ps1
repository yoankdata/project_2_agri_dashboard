$username = "admin@agri.com"
$password = "Password123!"
$baseUrl = "http://localhost:3000/api"

# Login
$session = Invoke-RestMethod -Uri "$baseUrl/session" -Method Post -Body (@{ username = $username; password = $password } | ConvertTo-Json) -ContentType "application/json"
$headers = @{ "X-Metabase-Session" = $session.id }

# Get Dash ID
$dash = (Invoke-RestMethod -Uri "$baseUrl/dashboard" -Method Get -Headers $headers) | Where-Object { $_.name -eq "Agri Intelligence V1" }
$dashId = $dash.id
Write-Output "Target Dashboard ID: $dashId"

# Get Card IDs
$cards = Invoke-RestMethod -Uri "$baseUrl/card" -Method Get -Headers $headers
$kpiCard = $cards | Where-Object { $_.name -like "*Global Performance KPIs*" } | Select-Object -First 1

Write-Output "KPI Card ID: $($kpiCard.id)"

if (-not $kpiCard) { Write-Error "KPI Card not found"; exit 1 }

# Function to add card
function Add-Card {
    param($dId, $cId)
    
    $body = @{
        cardId                 = $cId
        row                    = 0
        col                    = 0
        size_x                 = 18
        size_y                 = 4
        visualization_settings = @{}
    }
    
    $json = $body | ConvertTo-Json
    Write-Output "Payload: $json"
    
    try {
        Invoke-RestMethod -Uri "$baseUrl/dashboard/$dId/cards" -Method Post -Body $json -ContentType "application/json" -Headers $headers
        Write-Output "Success."
    }
    catch {
        Write-Output "Error adding card:"
        Write-Output $_.Exception.Message
        if ($_.Exception.Response) {
            $stream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            Write-Output "Response Body: $($reader.ReadToEnd())"
        }
    }
}

Add-Card -dId $dashId -cId $kpiCard.id
