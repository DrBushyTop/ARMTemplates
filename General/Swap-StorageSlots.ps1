param(
    [string] $productionAccount = $(throw "-productionAccount is required (production storage account name)"),
    [string] $stagingAccount = $(throw "-stagingAccount is required (staging storage account name)")
)

$ErrorActionPreference = 'Stop'

$productionContext = (Get-AzStorageAccount | Where-Object -Property StorageAccountName -eq $productionAccount).Context
$stagingContext = (Get-AzStorageAccount | Where-Object -Property StorageAccountName -eq $stagingAccount).Context

# Create containers if they do not exist
if (!(Get-AzStorageContainer 'temp' -Context $stagingContext -ErrorAction SilentlyContinue)) {New-AzStorageContainer -name 'temp' -Context $stagingContext} 
if (!(Get-AzStorageContainer '$web' -Context $stagingContext -ErrorAction SilentlyContinue)) {New-AzStorageContainer -name '$web' -Context $stagingContext} 
if (!(Get-AzStorageContainer '$web' -Context $productionContext -ErrorAction SilentlyContinue)) {New-AzStorageContainer -name '$web' -Context $productionContext} 

# Clean staging temp & copy current prod there
(Get-AzStorageBlob -Container 'temp' -Context $stagingContext | Remove-AzStorageBlob -Force) 1> $null
(Get-AzStorageBlob -Container '$web' -Context $productionContext | Start-AzStorageBlobCopy -DestContainer 'temp' -DestContext $stagingContext) 1> $null
(Get-AzStorageBlob -Container 'temp' -Context $stagingContext | Get-AzStorageBlobCopyState -WaitForComplete) 1> $null

# Clean prod before copy and then copy staging version to production
(Get-AzStorageBlob -Container '$web' -Context $productionContext | Remove-AzStorageBlob -Force) 1> $null
(Get-AzStorageBlob -Container '$web' -Context $stagingContext | Start-AzStorageBlobCopy -DestContainer '$web' -DestContext $productionContext) 1> $null
(Get-AzStorageBlob -Container '$web' -Context $productionContext | Get-AzStorageBlobCopyState -WaitForComplete) 1> $null

# Clean staging before copy and then copy old prod version there.
(Get-AzStorageBlob -Container '$web' -Context $stagingContext | Remove-AzStorageBlob -Force) 1> $null
(Get-AzStorageBlob -Container 'temp' -Context $stagingContext | Start-AzStorageBlobCopy -DestContainer '$web' -DestContext $stagingContext) 1> $null
(Get-AzStorageBlob -Container 'temp' -Context $stagingContext | Get-AzStorageBlobCopyState -WaitForComplete) 1> $null