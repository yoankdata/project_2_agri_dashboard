$username = "admin@agri.com"
$password = "Password123!"
$baseUrl = "http://localhost:3000/api"

# Login
$loginBody = @{ username = $username; password = $password }
$session = Invoke-RestMethod -Uri "$baseUrl/session" -Method Post -Body ($loginBody | ConvertTo-Json) -ContentType "application/json"
$sessionId = $session.id
$headers = @{ "X-Metabase-Session" = $sessionId }

# Get Databases Raw
$response = Invoke-WebRequest -Uri "$baseUrl/database" -Method Get -Headers $headers -UseBasicParsing
Write-Output "Raw Response Content:"
Write-Output $response.Content
