## Sets up permissions to get a SSL certificate from Key Vault from same or another subscription.
## Sets up Key Vault Contributor permissions to the Service Principal given in, but you can specify your own custom role too.

Param(
  [string] [Parameter(Mandatory=$true)] $keyVaultName,
  [string] [Parameter(Mandatory=$true)] $keyVaultRG,
  [string] [Parameter(Mandatory=$true)] $servicePrincipalObjectId,
  [string] [Parameter(Mandatory=$false)] $keyvaultSubscriptionId,
  [string] [Parameter(Mandatory=$false)] $customRoleDefinitionId,
  [switch] $government
)
# Setup "Microsoft Azure App Service" principal info
if ($govenrment) { $AppServiceRPSPId = "6a02c803-dafd-4136-b4c3-5a6f318b4714" }
else { $AppServiceRPSPId = "abfa0a7c-a6b6-4736-8310-5855508787cd" }

# Change to Key Vault Subscription if given. Otherwise use the one selected in context.
if ($keyvaultSubscriptionId) { Set-AzContext $keyvaultSubscriptionId}

# Get Key Vault info
$keyVaultID = (Get-AzResource -ResourceGroupName $keyVaultRG -Name $keyVaultName -ResourceType "Microsoft.KeyVault/vaults").ResourceId

# Get role definition IDs
if (!$customRoleDefinitionId) { $customRoleDefinitionId = (Get-AzRoleDefinition -RoleDefinitionName "Key Vault Contributor").Id }
$readerRoleDefinitionId = (Get-AzRoleDefinition -Name "Reader").Id

# Set required roleassignments
New-AzRoleAssignment -ObjectId $servicePrincipalObjectId -RoleDefinitionId $customRoleDefinitionId -Scope $keyVaultID
New-AzRoleAssignment -ApplicationId $AppServiceRPSPId -RoleDefinitionName "Reader" -Scope $keyVaultID
Set-AzKeyVaultAccessPolicy -ServicePrincipalName $AppServiceRPSPId -ResourceId $keyVaultID -PermissionsToSecrets "Get"