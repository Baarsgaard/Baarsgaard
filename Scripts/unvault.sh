#!/bin/bash

set -e
set -u
set -o pipefail

log() {
  if [ "$verbose" -eq 1 ]; then
    echo "$@"
  fi
}

log_error() {
  echo >&2 "$1"
  exit "$2"
}

showHelp() {
  cat <<EOF
Usage: ./set-secret.sh [-h|-u] <secret-name>
Fetch, Modify, Write, Secrets to/from Azure keyvault

 -h   -help       --help             Display this help.
      -version    --version          Print current version of the script.
 -v   -verbose    --verbose          Print more progress log message
 -b   -base64     --base64           Base64 Decode secret from vault and encode before writing secret to the vault. (Relies on 'base64')
 -u   -urlencode  --urlencode        URL Decode secret from vault and encode before writing secret to the vault.
 -j   -json       --json             Expand and minify JSON secrets. (Relies on 'jq')


 -t   -tenant        --tenant           Tenant id [TENANT_ID]
 -s   -subscription  --subscription     Subscription id  [SUBSCRIPTION_ID]
 -v   -vault         --vault            Name of keyvault [VAULT_NAME]

 <secret-name>                       Any secret in the selected key vault

EOF
}

verifyRuntime() {
  log "verifying environment and PATH"

  if [ -z "$1" ]; then
    log_error "<secret name> is missing, provide a secret to fetch from key vault" 1
  fi

  if [ -z "$TENANT_ID" ]; then
    log_error "TENANT_ID is not set" 1
  fi

  if [ -z "$SUBSCRIPTION_ID" ]; then
    log_error "SUBSCRIPTION_ID is not set" 1
  fi

  if [ -z "$VAULT_NAME" ]; then
    log_error "VAULT_NAME is not set" 1
  fi

  if ! which az >/dev/null; then
    log_error "Required package 'az' (azure cli) is missing in PATH" 1
  fi

  if ! which python3 >/dev/null; then
    log_error "Required package 'python3' is missing in PATH" 1
  fi
}

getSecret() {
  local VAULT_NAME=$1
  local SECRET=$2

  az keyvault \
    secret \
    show \
    --vault-name "$VAULT_NAME" \
    --name "$SECRET" |
    jq '.value' -r
}

setSecret() {
  local VAULT_NAME=$1
  local SECRET=$2
  local VALUE=$3

  log 'Writing/Updating Secret...'

  az keyvault \
    secret \
    set \
    --vault-name "$VAULT_NAME" \
    --name "$SECRET" \
    --value "$VALUE" >/dev/null

  log 'Secret Set/Updated'
}

base64Encode() {
  base64 -
}

base64Decode() {
  if ! which base64 >/dev/null; then
    log_error "Required package 'bsae64' is missing in PATH" 1
  fi
  base64 --decode -
}

urlEncode() {
  read -r string
  python3 -c "import urllib.parse, sys; print(urllib.parse.quote_plus(sys.argv[1]))" "$string"
}

urlDecode() {
  read -r string
  python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.argv[1]))" "$string"
}

jsonExpand() {
  if ! which jq >/dev/null; then
    log_error "Required package 'jq' is missing in PATH" 1
  fi
  jq -rM .

  if [ $? -eq 4 ]; then
    log_error "Secret is not valid JSON. Exiting" 4
  fi
}

jsonMinify() {
  jq -r tostring
}

azLogin() {
  if ! az account show >/dev/null; then
    log 'Logging in...'
    az login --tenant="$AZURE_TENANT_ID"
  fi

  log 'Setting account...'
  az account set --subscription="$AZURE_SUBSCRIPTION_ID" >/dev/null
}

modify() {
  local FILE=".secret"

  #
  # Get secret
  #
  azLogin
  log "Retrieving Secret from $VAULT_NAME..."
  getSecret "$VAULT_NAME" "$1" >$FILE 2>/dev/null || true

  # Store copy of secret to check for changes
  local SECRET_CHECK="$(cat "$FILE")"

  #
  # Decode/format secret
  #
  # Base64 DECODE
  if [ "$base64encode" -eq 1 ]; then
    local secret="$(cat $FILE | base64Decode)"
    echo "$secret" >"$FILE"
  fi
  # URL DECODE
  if [ "$urlencode" -eq 1 ]; then
    local secret="$(cat $FILE | urlDecode)"
    echo "$secret" >"$FILE"
  fi
  # JSON expand
  if [ "$json" -eq 1 ]; then
    local secret="$(cat $FILE | jsonExpand)"
    echo "$secret" >"$FILE"
  fi

  #
  # Open editor
  #
  log 'Opening default Editor'
  ${EDITOR:-/usr/bin/editor} "$FILE"

  if [ ! -s "$FILE" ]; then
    rm "$FILE"
    log_error "$1 Empty. Exiting without writing changes" 4
  fi

  local SECRET="$(cat "$FILE")"
  rm -f "$FILE"

  #
  # Encode/clean secret
  #
  # Minify JSON
  if [ "$json" -eq 1 ]; then
    SECRET="$(echo "$SECRET" | jsonMinify)"
  fi
  # URL ENCODE
  if [ "$urlencode" -eq 1 ]; then
    SECRET="$(echo "$SECRET" | urlEncode)"
  fi
  # Base64 ENCODE
  if [ "$base64encode" -eq 1 ]; then
    SECRET="$(echo "$SECRET" | base64Encode)"
  fi

  #
  # Exit without writing if secret did not change
  #
  if [ "$SECRET" == "$SECRET_CHECK" ]; then
    echo "$1 Unchanged"
    exit 0
  fi

  #
  # Write secret to vault
  #
  echo "$1 Overwritten"
  setSecret "$VAULT_NAME" "$1" "$SECRET"
}

main() {
  version='1.0.0'
  verbose=0
  base64encode=0
  urlencode=0
  json=0

  # -o is for short options like -v
  # -l is for long options with double dash like --version
  # -a is for long options with single dash like -version
  options=$(getopt -l "help,version,verbose,base64,urlencode,json,vault::,subscription::,tenant::" -o "hVbujv::s::t::" -a -q -- "$@")

  # set --:
  # If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters
  # are set to the arguments, even if some of them begin with a ‘-’.
  eval set -- "$options"

  while true; do
    case $1 in
    -h | --help)
      showHelp
      exit 0
      ;;
    --version)
      echo "$version"
      exit 0
      ;;
    -V | --verbose)
      verbose=1
      ;;
    -b | --base64)
      base64encode=1
      ;;
    -u | --urlencode)
      urlencode=1
      ;;
    -j | --json)
      json=1
      ;;
    -v | --vault)
      shift
      VAULT_NAME="$1"
      ;;
    -t | --tenant)
      shift
      TENANT_ID="$1"
      ;;
    -s | --subscription)
      shift
      SUBSCRIPTION_ID="$1"
      ;;
    --)
      shift
      break
      ;;
    esac
    shift
  done

  verifyRuntime "$1"
  modify "$1"
}

main "$@"
