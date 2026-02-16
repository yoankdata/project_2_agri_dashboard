$username = "admin@agri.com"
$password = "Password123!"
$baseUrl = "http://localhost:3000/api"

# 1. Login
$loginBody = @{ username = $username; password = $password }
$session = Invoke-RestMethod -Uri "$baseUrl/session" -Method Post -Body ($loginBody | ConvertTo-Json) -ContentType "application/json"
$sessionId = $session.id
$headers = @{ "X-Metabase-Session" = $sessionId }

# 2. Get Databases
$response = Invoke-RestMethod -Uri "$baseUrl/database" -Method Get -Headers $headers
$dbs = $response.data

Write-Output "Existing Databases:"
if ($dbs) {
    $dbs | ForEach-Object { Write-Output "- $($_.name) (ID: $($_.id))" }
}
else {
    Write-Output "No databases found in response."
}

$agriDb = $dbs | Where-Object { $_.name -eq "Agri DWH" }

if (-not $agriDb) {
    Write-Output "Database 'Agri DWH' not found. Adding it..."
    $dbPayload = @{
        engine  = "postgres"
        name    = "Agri DWH"
        details = @{
            host                          = "host.docker.internal"
            port                          = 5432
            dbname                        = "agri_dwh"
            user                          = "agri"
            password                      = "agri"
            "let-user-control-scheduling" = $false
        }
    }
    try {
        $agriDb = Invoke-RestMethod -Uri "$baseUrl/database" -Method Post -Body ($dbPayload | ConvertTo-Json) -ContentType "application/json" -Headers $headers
        Write-Output "Added Database: $($agriDb.name) (ID: $($agriDb.id))"
    }
    catch {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $body = $reader.ReadToEnd()
        Write-Error "Failed to add database. Status: $($_.Exception.Response.StatusCode)"
        Write-Error "Body: $body"
        exit 1
    }
}
else {
    Write-Output "Found Database: $($agriDb.name) (ID: $($agriDb.id))"
}

# 3. Get Tables
# Give it a moment to sync if just added
if (-not $agriDb.tables) {
    Start-Sleep -Seconds 2
}

# Fetch metadata (tables)
# Note: /api/database returns broad info. /api/database/:id/metadata includes tables.
# Or if just added, use the response from POST which might be partial.
$metadata = Invoke-RestMethod -Uri "$baseUrl/database/$($agriDb.id)/metadata" -Method Get -Headers $headers

$martTables = $metadata.tables | Where-Object { $_.schema -eq "mart" }

if ($martTables) {
    Write-Output "Tables in 'mart' schema:"
    $martTables | ForEach-Object { Write-Output "- $($_.name)" }
}
else {
    Write-Warning "No tables found in 'mart' schema yet. Triggering sync..."
    Invoke-RestMethod -Uri "$baseUrl/database/$($agriDb.id)/sync_schema" -Method Post -Headers $headers
    Start-Sleep -Seconds 5
    $metadata = Invoke-RestMethod -Uri "$baseUrl/database/$($agriDb.id)/metadata" -Method Get -Headers $headers
    $martTables = $metadata.tables | Where-Object { $_.schema -eq "mart" }
    
    if ($martTables) {
        Write-Output "Tables in 'mart' schema (after sync):"
        $martTables | ForEach-Object { Write-Output "- $($_.name)" }
    }
    else {
        Write-Output "Full table list found (debug):"
        $metadata.tables | ForEach-Object { Write-Output "- Schema: $($_.schema), Table: $($_.name)" }
    }
}
