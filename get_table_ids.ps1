$username = "admin@agri.com"
$password = "Password123!"
$baseUrl = "http://localhost:3000/api"

# Login
$session = Invoke-RestMethod -Uri "$baseUrl/session" -Method Post -Body (@{ username = $username; password = $password } | ConvertTo-Json) -ContentType "application/json"
$headers = @{ "X-Metabase-Session" = $session.id }

# Get DB ID
$agriDb = (Invoke-RestMethod -Uri "$baseUrl/database" -Method Get -Headers $headers).data | Where-Object { $_.name -eq "Agri DWH" }
$dbId = $agriDb.id
Write-Output "DB ID: $dbId"

# Sync Schema
Write-Output "Syncing schema..."
Invoke-RestMethod -Uri "$baseUrl/database/$dbId/sync_schema" -Method Post -Headers $headers
# Wait for sync
Start-Sleep -Seconds 3

# Get Tables
$metadata = Invoke-RestMethod -Uri "$baseUrl/database/$dbId/metadata" -Method Get -Headers $headers
$tables = $metadata.tables | Where-Object { $_.schema -eq "mart" }

$targetTables = @("kpi_global", "volatility_analysis", "logistics_margin", "data_quality_metrics")
$tableIds = @{}

foreach ($t in $tables) {
    if ($targetTables -contains $t.name) {
        $tableIds[$t.name] = $t.id
        Write-Output "Found Table: $($t.name) ID: $($t.id)"
    }
}

$tableIds | ConvertTo-Json | Set-Content "table_ids.json"
