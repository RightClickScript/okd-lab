# Import the YAML parsing module
Install-Module -Name powershell-yaml -Scope CurrentUser

# Define the relative path to the compose.yaml file
$composeFilePath = ".\.devcontainer\compose.yaml"

# Prompt the user for the service name
$serviceName = Read-Host -Prompt "Enter the service name"

# Check if the user entered a value
if (-not $serviceName) {
    Write-Host "Error: Service name cannot be empty. Exiting."
    exit 1
}

# Check if the compose.yaml file exists
if (-not (Test-Path -Path $composeFilePath)) {
    Write-Host "Error: compose.yaml file not found at $composeFilePath"
    exit 1
}

# Read and parse the YAML file
$yamlContent = Get-Content -Path $composeFilePath -Raw

# Replace the SERVICE_NAME placeholder with the actual service name
$yamlContent = $yamlContent -replace '\$\{SERVICE_NAME\}', $serviceName

# Write the updated YAML content back to the file
Set-Content -Path $composeFilePath -Value $yamlContent
$yamlContent = Get-Content -Path $composeFilePath -Raw
$services = $yamlContent | ConvertFrom-Yaml
# Iterate through the services and their volumes
foreach ($serviceName in ($services.services.Keys)) {
    $service = $services.services[$serviceName]
    if ($service.volumes) {
        foreach ($volume in $service.volumes) {
            $source = $volume.source.Split("/")[-1]
            Write-Host $source
            # Skip if the source is ".."
            if ($source -eq "..") {
                Write-Host "Skipping source: $source"
                continue
            }

            # Create the directory if it doesn't exist
            if (-not (Test-Path -Path ".\$($source)")) {
                Write-Host "Creating directory: $source"
                New-Item -ItemType Directory -Path ".\$($source)" -Force
            } else {
                Write-Host "Directory already exists: $source"
            }
        }
    }
}