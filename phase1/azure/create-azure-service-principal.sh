#!/bin/bash
# exit on errors
set -e

if ! which jq > /dev/null; then
    echo "Can not find the 'jq' program, please install it"
    exit 1
fi

if ! which azure > /dev/null; then
    echo "Can not find the 'azure' command line tools, please install them"
    exit 1
fi

# get the tenant and subscription id
tenant_id=$(azure account show --json | jq ".[] | .tenantId")
sub_id=$(azure account show --json | jq ".[] | .id")

# setup the app
echo Please enter your application name:
read app_name

echo Please enter your application url, can be bogus:
read app_url

echo Please enter your application secret:
read -s client_secret

echo Please enter your application secret again:
read -s client_secret_2

if [[ "${client_secret}" != "${client_secret_2}" ]]; then
    echo "Secrets do not match!"
    exit 1
fi

raw_json=$(azure ad app create -n ${app_name} -i ${app_url} --home-page ${app_url} -p ${client_secret} --json)

sleep 5

echo ${raw_json}

app_id=$(echo $raw_json | jq ".appId")

# strip quotes
app_id="${app_id%\"}"
app_id="${app_id#\"}"
sub_id="${sub_id%\"}"
sub_id="${sub_id#\"}"

# Create the service principal
azure ad sp create --applicationId ${app_id} --json

# eventual consistency ftw!
sleep 5

# Create the role assignment for the service principal
azure role assignment create --spn ${app_url} -o "Owner" -c /subscriptions/${sub_id}

echo Here are the parameters to paste into your config
echo

echo phase1.azure.tenant_id = "${tenant_id}"
echo phase1.azure.subscription_id = "\"${sub_id}\""
echo phase1.azure.client_id = "\"${app_id}\""
echo phase1.azure.client_secret = "${client_secret}"


