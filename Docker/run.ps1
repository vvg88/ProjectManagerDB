# Add boolean parameter to optionally start psql; prompt for password and start container
param(
	[bool]$startPsql = $false
)

# Prompt user to enter password
$password = Read-Host "Enter PostgreSQL password" -AsSecureString

# Convert SecureString to plain text (for env var)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($password))

# Run Docker container
Write-Host "Starting PostgreSQL container..." -ForegroundColor Green
docker run --name project_manager_db -e "POSTGRES_PASSWORD=$plainPassword" -p 5432:5432 -d postgres

if ($startPsql) {
    # Small delay to allow container services to settle before exec
    write-Host "Waiting for container to initialize..." -ForegroundColor Yellow
	Start-Sleep -Seconds 5
	
    Write-Host "Launching psql inside container 'project_manager_db'..." -ForegroundColor Green
	docker exec -it project_manager_db psql -U postgres -d postgres
}
