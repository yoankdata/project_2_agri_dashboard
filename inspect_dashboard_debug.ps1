$username = "admin@agri.com"
$password = "Password123!"
$baseUrl = "http://localhost:3000/api"

# Login
$session = Invoke-RestMethod -Uri "$baseUrl/session" -Method Post -Body (@{ username = $username; password = $password } | ConvertTo-Json) -ContentType "application/json"
$headers = @{ "X-Metabase-Session" = $session.id }

# Get Dashboard Details
$dashes = Invoke-RestMethod -Uri "$baseUrl/dashboard" -Method Get -Headers $headers
$dash = $dashes | Where-Object { $_.name -eq "Agri Intelligence V1" }

if ($dash) {
    Write-Output "Dashboard Found: $($dash.id)"
    
    # Get DashCards
    $dashDetail = Invoke-RestMethod -Uri "$baseUrl/dashboard/$($dash.id)" -Method Get -Headers $headers
    Write-Output "Cards on Dashboard: $($dashDetail.ordered_cards.Count)"
    
    if ($dashDetail.ordered_cards) {
        $dashDetail.ordered_cards | ForEach-Object {
            Write-Output " - DashCard ID: $($_.id), Card ID: $($_.card_id), Size: $($_.size_x)x$($_.size_y)"
        }
    }
    else {
        Write-Output "No cards found on dashboard (ordered_cards is empty)."
    }

    # Verify if Cards exist in general
    Write-Output "`nChecking database for created cards..."
    $cards = Invoke-RestMethod -Uri "$baseUrl/card" -Method Get -Headers $headers
    $myCards = $cards | Where-Object { $_.name -in "Global Performance KPIs", "Volatility & Risk Analysis", "Logistics & Margin", "Data Quality Metrics" }
    
    if ($myCards) {
        Write-Output "Found the following cards in the system:"
        $myCards | ForEach-Object { Write-Output " - Card: $($_.name) (ID: $($_.id))" }
        
        # Save card IDs for re-attempt
        $cardMap = @{}
        $myCards | ForEach-Object { $cardMap[$_.name] = $_.id }
        $cardMap | ConvertTo-Json | Set-Content "debug_card_ids.json"
    }
    else {
        Write-Output "Cards were NOT found in the system. They might not have been created."
    }

}
else {
    Write-Error "Dashboard 'Agri Intelligence V1' not found."
}
