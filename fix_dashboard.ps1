$username = "admin@agri.com"
$password = "Password123!"
$baseUrl = "http://localhost:3000/api"

# Login
$session = Invoke-RestMethod -Uri "$baseUrl/session" -Method Post -Body (@{ username = $username; password = $password } | ConvertTo-Json) -ContentType "application/json"
$headers = @{ "X-Metabase-Session" = $session.id }

# Get Dashboard ID
$dash = (Invoke-RestMethod -Uri "$baseUrl/dashboard" -Method Get -Headers $headers) | Where-Object { $_.name -eq "Agri Intelligence V1" }
$dashId = $dash.id
Write-Output "Dashboard ID: $dashId"

# Get Card IDs
$cards = Invoke-RestMethod -Uri "$baseUrl/card" -Method Get -Headers $headers
$cardMap = @{}
$cards | Where-Object { $_.name -in "Global Performance KPIs", "Volatility & Risk Analysis", "Logistics & Margin", "Data Quality Metrics" } | ForEach-Object {
    $cardMap[$_.name] = $_.id
    Write-Output "Found Card '$($_.name)' with ID: $($_.id)"
}

# Add Cards Function
function Add-Card-To-Dash {
    param ($dashId, $cardId, $x, $y, $w, $h)
    
    # Payload details: For adding a saved question, use cardId.
    $dashCard = @{
        cardId                 = $cardId
        row                    = $y
        col                    = $x
        size_x                 = $w
        size_y                 = $h
        visualization_settings = @{}
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$baseUrl/dashboard/$dashId/cards" -Method Post -Body ($dashCard | ConvertTo-Json -Depth 5) -ContentType "application/json" -Headers $headers
        Write-Output "Added card $cardId to dashboard (ID: $($response.id))"
    }
    catch {
        Write-Error "Failed to add card $cardId"
        Write-Error $_.Exception.Message
        # Print body if available
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Error $reader.ReadToEnd()
        }
    }
}

# Layout 2x2
# Grid is 18 wide.
if ($cardMap["Global Performance KPIs"]) {
    Add-Card-To-Dash $dashId $cardMap["Global Performance KPIs"] 0 0 18 4
}
if ($cardMap["Volatility & Risk Analysis"]) {
    Add-Card-To-Dash $dashId $cardMap["Volatility & Risk Analysis"] 0 4 9 6
}
if ($cardMap["Logistics & Margin"]) {
    Add-Card-To-Dash $dashId $cardMap["Logistics & Margin"] 9 4 9 6
}
if ($cardMap["Data Quality Metrics"]) {
    Add-Card-To-Dash $dashId $cardMap["Data Quality Metrics"] 0 10 18 6
}
