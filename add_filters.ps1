$username = "admin@agri.com"
$password = "Password123!"
$baseUrl = "http://localhost:3000/api"

# Login
$session = Invoke-RestMethod -Uri "$baseUrl/session" -Method Post -Body (@{ username = $username; password = $password } | ConvertTo-Json) -ContentType "application/json"
$headers = @{ "X-Metabase-Session" = $session.id }

# Get Dashboard
$dashes = Invoke-RestMethod -Uri "$baseUrl/dashboard" -Method Get -Headers $headers
$dash = $dashes | Where-Object { $_.name -eq "Agri Intelligence V1" }
$dashId = $dash.id

if (-not $dashId) { Write-Error "Dashboard not found"; exit 1 }

# Define Parameters (Filters)
$parameters = @(
    @{
        name      = "Region"
        slug      = "region"
        id        = "parameter_region"
        type      = "category"
        sectionId = "location"
    },
    @{
        name = "Crop"
        slug = "crop"
        id   = "parameter_crop"
        type = "category"
    }
)

# Update Dashboard to have parameters
$dashPayload = @{ parameters = $parameters }
Invoke-RestMethod -Uri "$baseUrl/dashboard/$dashId" -Method Put -Body ($dashPayload | ConvertTo-Json -Depth 10) -ContentType "application/json" -Headers $headers

# Now we need to map these parameters to cards.
# This is tricky via API without knowing exact card_id in dash_card.
# We'll skip complex mapping for now as it requires iterating dashcards and mapping field IDs.
# Instead, we just ensured the filters exist on the dashboard UI.
Write-Output "Filters added to dashboard definition. Mapping requires manual field ID lookup."
