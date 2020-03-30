# Variables
$tenantId = '4f534499-b9d1-4872-8b22-47fb237c1609'
$subscriptionId = '54d3d134-5246-418a-b167-9c8c86a7c44d'
$deploymentPrefix = 'east-saca'
$rgName = "$deploymentPrefix-rg"
$rgLocation = 'East US'
$environmentName = 'AzureCloud'
$templateBasePath = 'C:\Github_Repos\f5-azure-saca\SACAv2\3NIC_1Tier_HA\bigiq'
$kvName = "$deploymentPrefix-kv"
$sacaAdminSecret = 'saca-admin-username'
$sacaAdminPwdSecret = 'saca-admin-password'
$f5BigIqUsernameSecret = 'f5-bigiq-username'
$f5BigIqPwdSecret = 'f5-bigiq-password'

# Login to Azure
Write-Host "Checking context...";
$context = Get-AzContext
if($null -ne $context){
  if(!(($context.Subscription.TenantId -match $tenantId) -and ($context.Subscription.Id -match $subscriptionId))){
    do{
      Remove-AzAccount -ErrorAction SilentlyContinue | Out-Null
      $context = Get-AzContext
      }
    until($null -eq $context)
    Login-AzAccount -EnvironmentName $environmentName -TenantId $tenantId -Subscription $subscriptionId
    }
  }
else{
  Login-AzAccount -EnvironmentName $environmentName -TenantId $tenantId -Subscription $subscriptionId
  }

# Create Resource Group
$rg = Get-AzResourceGroup -Name $rgName -Location $rgLocation -ErrorAction Ignore
if($null -eq $rg)
    {
        Write-Host "Creating Resource Group $rgName..."
        $rg = New-AzResourceGroup -Name $rgName -Location $rgLocation
    }
else
    {
        Write-Host "Resource Group with name $rgName already exist" -ForegroundColor Green
    }

# Grab secrets from Key Vault
if($null -eq (Get-AzKeyVault -VaultName $kvName -ErrorAction Ignore))
    {
      Throw "The Key Vault $kvName does not exist"
    }

$adminUsername = (Get-AzKeyVaultSecret -VaultName $kvName -Name $sacaAdminSecret).SecretValueText
$adminPassword = ConvertTo-SecureString -String (Get-AzKeyVaultSecret -VaultName $kvName -Name $sacaAdminPwdSecret).SecretValueText -AsPlainText -Force
$f5BigIqUsername = (Get-AzKeyVaultSecret -VaultName $kvName -Name $f5BigIqUsernameSecret).SecretValueText
$f5BigIqPwd = ConvertTo-SecureString -String (Get-AzKeyVaultSecret -VaultName $kvName -Name $f5BigIqPwdSecret).SecretValueText -AsPlainText -Force

# Test template
Test-AzResourceGroupDeployment -ResourceGroupName $rgName `
    -TemplateFile "$templateBasePath\azureDeploy.json" `
    -TemplateParameterFile "$templateBasePath\deploymentParameters.json" `
    -adminUsername $adminUsername `
    -adminPasswordOrKey $adminPassword `
    -WindowsAdminPassword $adminPassword `
    -bigIqUsername $f5BigIqUsername `
    -bigIqPassword $f5BigIqPwd `
    -Mode Incremental `
    -Verbose