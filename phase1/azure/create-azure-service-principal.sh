#!/bin/bash

set -eu -o pipefail

## TODO: implement RG scoped auth

## options
while :; do
	case ${1:-} in
		--subscription-id=?*)
			subscription_id=${1#*=}
			;;
		--subscription-id=)
			printf 'ERROR: "--subscription-id" requires a non-empty option argument.\n' >&2
			exit 1
			;;
		--name=?*)
			app_name=${1#*=}
			;;
		--name=)
			printf 'ERROR: "--name" requires a non-empty option argument.\n' >&2
			exit 1
			;;
		--app-url=?*)
			app_url=${1#*=}
			;;
		--app-url=)
			printf 'ERROR: "--app-url" requires a non-empty option argument.\n' >&2
			exit 1
			;;
		--secret=?*)
			client_secret=${1#*=}
			;;
		--secret=)
			printf 'ERROR: "--secret" requires a non-empty option argument.\n' >&2
			exit 1
			;;
		--location=?*)
			location=${1#*=}
			;;
		--location=)
			printf 'ERROR: "--location" requires a non-empty option argument.\n' >&2
			exit
			;;
		--resource-group=?*)
			printf 'ERROR: "--resource-group" is not currently implmented.' >&2
			exit 1
			;;
		--resource-group=)
			printf 'ERROR: "--resource-group" is not currently implmented.' >&2
			#printf 'ERROR: "--resource-group" requires a non-empty option argument.\n' >&2
			exit 1
			;;
		--output-format=?*)
			output_format=${1#*=}
			;;
		--output-format=)
			printf 'ERROR: "--output_format" requires a non-empty option argument.\n' >&2
			exit 1
			;;
		--)
			shift
			break
			;;
		-?*)
			printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
			;;
		*)
			break
	esac

	shift
done

[[ ! -z "${subscription_id:-}" ]] || (printf 'ERROR: "--subscription-id" required.\n' >&2 && exit 1)
[[ ! -z "${app_url:-}" ]] || (printf 'ERROR: "--app-url" required.\n' >&2 && exit)
[[ ! -z "${client_secret:-}" ]] || (printf 'ERROR: "--client_secret" required.\n' >&2 && exit)

if [[ ! -z "${resource_group:-}" && -z "${location:-}" ]]; then
	printf 'ERROR: "--location" required when "--resource-group is specified.\n' >&2 && exit
fi

## requirements
which jq >/dev/null || (printf "Can not find the 'jq' program, please install it.\n" >&2 && exit 1)
which azure >/dev/null || (printf "Can not find the 'azure' program, please install it.\n" >&2 exit 1)

## ensure logged in
azure account show &>/dev/null || azure login
tenant_id=$(azure account show --json | jq -r ".[] | .tenantId")

raw_json=$(azure ad app create -n ${app_name} -i ${app_url} --home-page ${app_url} -p ${client_secret} --json)
app_id=$(echo $raw_json | jq -r '.appId')

## Create the service principal
azure ad sp create --applicationId ${app_id} >/dev/null

## Create the role assignment for the service principal
duration=5
elapsed=0
while true; do
	# TODO: backoff
	if azure role assignment create --spn ${app_url} -o "Owner" -c /subscriptions/${subscription_id} &>/dev/null ; then
		break
	fi
	# eventual consistency ftw!
	printf "WARNING: Role assignment failed. Waiting to retry role assignment. (elapsed: ${elapsed})\n" >&2
	sleep ${duration}
	elapsed=$((${elapsed} + ${duration}))
done

## Output
case "${output_format:-}" in
	"json")
		output=".tenant_id=\"${tenant_id}\"|.subscription_id=\"${subscription_id}\"|.client_id=\"${app_url}\"|.client_secret=\"${client_secret}\""
		jq -n "${output}"
		;;
	"text")
		echo tenant_id = "${tenant_id}"
		echo subscription_id = "${subscription_id}"
		echo client_id = "\"${app_url}\""
		echo client_secret = "${client_secret}"
		;;
esac
