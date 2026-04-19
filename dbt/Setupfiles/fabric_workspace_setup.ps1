# =============================================================================
# fabric_workspace_setup.ps1
# Creates the 3 FreshCart workspaces (dev / test / prod) via Fabric REST API
# Pre-requisites:
#   - Az PowerShell module:  Install-Module Az -Scope CurrentUser
#   - Fabric capacity already provisioned in Azure portal (F2 or higher)
#   - You are logged in:     Connect-AzAccount
# =============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$TenantId,

    [Parameter(Mandatory=$true)]
    [string]$CapacityId,           # The Fabric capacity GUID from Azure portal

    [string]$AdminGroupObjectId    # Optional: AAD group to assign as workspace admin
)

# ---------------------------------------------------------------------------
# Authenticate and get Fabric token
# ---------------------------------------------------------------------------
Write-Host "Authenticating to Microsoft Fabric..." -ForegroundColor Cyan

$token = (Get-AzAccessToken -ResourceUrl "https://api.fabric.microsoft.com").Token
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}

$fabricApi = "https://api.fabric.microsoft.com/v1"

# ---------------------------------------------------------------------------
# Workspace definitions
# ---------------------------------------------------------------------------
$workspaces = @(
    @{ name = "FreshCart-Dev";  description = "FreshCart Analytics — Development";  env = "dev"  },
    @{ name = "FreshCart-Test"; description = "FreshCart Analytics — Test/Staging"; env = "test" },
    @{ name = "FreshCart-Prod"; description = "FreshCart Analytics — Production";   env = "prod" }
)

$createdWorkspaces = @{}

# ---------------------------------------------------------------------------
# Create each workspace and assign to capacity
# ---------------------------------------------------------------------------
foreach ($ws in $workspaces) {

    Write-Host "`nCreating workspace: $($ws.name)" -ForegroundColor Yellow

    # Create workspace
    $body = @{
        displayName = $ws.name
        description = $ws.description
    } | ConvertTo-Json

    $response = Invoke-RestMethod `
        -Uri     "$fabricApi/workspaces" `
        -Method  POST `
        -Headers $headers `
        -Body    $body

    $workspaceId = $response.id
    $createdWorkspaces[$ws.env] = $workspaceId
    Write-Host "  ✅ Created workspace ID: $workspaceId" -ForegroundColor Green

    # Assign to Fabric capacity
    $capacityBody = @{ capacityId = $CapacityId } | ConvertTo-Json

    Invoke-RestMethod `
        -Uri     "$fabricApi/workspaces/$workspaceId/assignToCapacity" `
        -Method  POST `
        -Headers $headers `
        -Body    $capacityBody

    Write-Host "  ✅ Assigned to capacity: $CapacityId" -ForegroundColor Green

    # Assign admin group if provided
    if ($AdminGroupObjectId) {
        $memberBody = @{
            principal = @{
                id   = $AdminGroupObjectId
                type = "Group"
            }
            role = "Admin"
        } | ConvertTo-Json -Depth 3

        Invoke-RestMethod `
            -Uri     "$fabricApi/workspaces/$workspaceId/roleAssignments" `
            -Method  POST `
            -Headers $headers `
            -Body    $memberBody

        Write-Host "  ✅ Admin group assigned" -ForegroundColor Green
    }
}

# ---------------------------------------------------------------------------
# Output workspace IDs — copy these into your profiles.yml / GitHub Secrets
# ---------------------------------------------------------------------------
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "WORKSPACE IDs — Save these as GitHub Secrets" -ForegroundColor Cyan
Write-Host "============================================================"

foreach ($env in @("dev", "test", "prod")) {
    Write-Host "  $($env.ToUpper()) Workspace ID: $($createdWorkspaces[$env])"
}

Write-Host "`nNext steps:"
Write-Host "  1. Open each workspace in Fabric portal"
Write-Host "  2. Create a Lakehouse named 'FreshCart_Lakehouse' in each"
Write-Host "  3. Create a Data Warehouse named 'FreshCart_DW' in each"
Write-Host "  4. Run lakehouse_zones_setup.py notebook in each Lakehouse"
Write-Host "  5. Register the Service Principals in each workspace (Contributor role)"
Write-Host "============================================================"
