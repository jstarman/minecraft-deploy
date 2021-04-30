Remove-Item env:TF_VAR*

$subscriptionName=$(az account show --query name -o tsv)
$subscriptionId=$(az account show --query id -o tsv)

Get-Content .env | Foreach-Object{
    $var = $_.Split('=')
    Set-Item -Path "env:TF_VAR_$($var[0])" -Value $var[1]
}

Write-Output "Azure resources names"
Write-Output "Subscription:    $subscriptionName"
Write-Output "SubscriptionId:  $subscriptionId"
Get-ChildItem env:TF_VAR*

$confirmation = Read-Host "Are you Sure You Want To Proceed(y/n)?"
if ($confirmation -eq 'n') {
    Write-Output "Exiting"
    exit
}

terraform init -input=false -backend=true -reconfigure -upgrade `
  -backend-config="resource_group_name=$env:TF_VAR_resource_group" `
  -backend-config="storage_account_name=$env:TF_VAR_storage_account" `
  -backend-config="container_name=$env:TF_VAR_storage_container"

Write-Output "Terraform plan"
terraform plan

Write-Output "Terraform apply"
terraform apply -auto-approve