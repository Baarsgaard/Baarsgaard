#!/bin/bash

set -eu
set -o pipefail

log() {
  if [ "$verbose" -eq 1 ]; then
    echo "$@"
  fi
}

log_error() {
  echo >&2 "$1"
  exit "${2:-1}"
}

show_help() {
  cat <<EOF
  Manipulate secrets in Azure vault.
  Usage: ./unvault.sh [action] [options] <secret-name>

  <secret-name>   Required; Any secret in the key vault

  Actions:
    modify   Default; Opens secret in default text editor.
    create            Create a non-existent secret.
    print             Skip opening the editor and print secret to stdout.
    restore           Restores a soft-deleted secret.
    delete            Deletes a secret. (Unless soft delete is enabled)

  Options:
   -h    --help            Display this help.
         --version         Print current version of the script.
   -V    --verbose         Print more progress log message
   -t    --tenant          Tenant id [TENANT_ID]
   -s    --subscription    Subscription id  [SUBSCRIPTION_ID]
   -v    --vault           Name of keyvault [VAULT_NAME]
   -E    --editor

  Encodings
   -b   --base64          Base64 Decode secret from vault and encode before writing secret to the vault. (Uses 'base64')
   -u   --urlencode       URL Decode secret from vault and encode before writing secret to the vault.

  Formatters
   -f   --format          [json, yaml] Expand and minify secret. Uses jq and yq
   -e   --extension       Custom file extension [json, cs, yml], will override formatter, useful with EDITOR highlight settings

EOF
}

verify_runtime() {
  log "verifying environment and PATH"

  if [ -z "$1" ]; then
    log_error "<secret name> is missing, provide a secret to fetch from key vault"
  fi

  if [ -z "${TENANT_ID:=$ARM_TENANT_ID}" ]; then
    log_error "TENANT_ID is not set"
  fi

  if [ -z "${SUBSCRIPTION_ID:=$ARM_SUBSCRIPTION_ID}" ]; then
    log_error "SUBSCRIPTION_ID is not set"
  fi

  if [ -z "$VAULT_NAME" ]; then
    log_error "VAULT_NAME is not set"
  fi

  if ! which az >/dev/null; then
    log_error "Required package 'az' (azure cli) is missing in PATH"
  fi

  if ! which python3 >/dev/null; then
    log_error "Required package 'python3' is missing in PATH"
  fi
}

base64_encode() {
  if [[ $# == 0 ]]; then
    base64 -
  else
    echo "$1" | base64 -
  fi
}
base64_decode() {
  if ! which base64 >/dev/null; then
    log_error "Required package 'bsae64' is missing in PATH" 1
  fi

  if [[ $# == 0 ]]; then
    base64 --decode -
  else
    echo "$1" | base64 --decode -
  fi
}

url_encode() {
  if [[ $# == 0 ]]; then
    read -r string
  else
    string="$1"
  fi
  python3 -c "import urllib.parse, sys; print(urllib.parse.quote_plus(sys.argv[1]))" "$string"
}
url_decode() {
  if [[ $# == 0 ]]; then
    read -r string
  else
    string="$1"
  fi
  python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.argv[1]))" "$string"
}

json_display() {
  if ! which jq >/dev/null; then
    log_error "Required package 'jq' is missing in PATH" 1
  fi

  if [[ $# == 0 ]]; then
    jq -rM .
  else
    echo "$1" | jq -rM .
  fi

  if [ $? -eq 4 ]; then
    log_error "Secret is not valid JSON. Exiting" 4
  fi
}
# shellcheck disable=SC2120
json_minify() {
  if [[ $# == 0 ]]; then
    jq -rcM .
  else
    echo "$1" | jq -rcM .
  fi
}

yaml_display() {
  if ! which yq >/dev/null; then
    log_error "Required package 'yq' is missing in PATH" 1
  fi
  if ! which jq >/dev/null; then
    log_error "Required package 'jq' is missing in PATH" 1
  fi

  if [[ $# == 0 ]]; then
    yq --no-colors .
  else
    echo "$1" | yq --no-colors .
  fi

  if [ $? -eq 4 ]; then
    log_error "Secret is not valid JSON. Exiting" 4
  fi
}
yaml_minify() {
  if [[ $# == 0 ]]; then
    yq --no-colors --output-format json | json_minify
  else
    echo "$1" | yq --no-colors --output-format json | json_minify
  fi
}

az_login() {
  if ! az account show >/dev/null; then
    log 'Logging in...'
    az login --tenant="$TENANT_ID"
  fi

  log 'Setting account...'
  az account set --subscription="$SUBSCRIPTION_ID" >/dev/null
}

get_secret() {
  local SECRET="$1"

  az keyvault secret show \
    --vault-name "$VAULT_NAME" \
    --name "$SECRET" |
    jq -r '.value'
}
set_secret() {
  local SECRET="$1"
  local VALUE="$2"

  log 'Writing/Updating Secret...'

  az keyvault secret set \
    --vault-name "$VAULT_NAME" \
    --name "$SECRET" \
    --value "$VALUE" >/dev/null

  log 'Secret Set/Updated'
}
delete_secret() {
  local SECRET=$1

  log "Deleting secret"
  az keyvault secret delete \
    --vault-name "$VAULT_NAME" \
    --name "$SECRET"
}
recover_secret() {
  local SECRET=$1

  log "Recovering secret"
  az keyvault secret recover \
    --vault-name "$VAULT_NAME" \
    --name "$SECRET"
}
modify_secret() {
  log "Retrieving Secret from $VAULT_NAME..."
  local secret
  secret=$(get_secret "$1")

  # Carbon Copy. Check for changes after opening editor
  local secret_check="$secret"

  # Decode/format secret
  if [ -n "$encoder" ]; then
    local secret="$("$encoder"'_decode' "$secret")"
  fi
  if [ -n "$formatter" ]; then
    local secret="$("$formatter"'_display' "$secret")"
  fi

  local FILE=$(mktemp --suffix="${extensionPriority:=$extension}" '.secret.XXXXXXXX')
  trap 'rm -f $FILE' EXIT
  echo "$secret" >"$FILE"

  # Open editor
  log 'Opening default Editor'
  ${EDITOR:-/usr/bin/editor} "$FILE"

  if [ ! -s "$FILE" ]; then
    log_error "$1 Empty. Exiting without writing changes" 4
  fi

  local SECRET="$(cat "$FILE")"

  # Encode/minify secret
  if [ -n "$formatter" ] && [ "$formatter" ]; then
    secret="$("$formatter"'_minify' "$secret")"
  fi

  if [ -n "$encoder" ]; then
    secret="$("$encoder"'_encode' "$secret")"
  fi

  # Exit early if secret did not change
  if [ "$secret" == "$secret_check" ]; then
    echo "$1 Unchanged"
    exit 0
  fi

  # Write secret to vault
  set_secret "$1" "$secret"
  echo "$1 Overwritten"
}
create_secret() {
  local SECRET="$1"
  local VALUE="$2"

  log 'Creating Secret...'

  az keyvault secret set \
    --vault-name "$VAULT_NAME" \
    --name "$SECRET" \
    --value "$VALUE" >/dev/null

  log 'Secret Set/Updated'
}
print_secret() {
  log "Retrieving Secret from $VAULT_NAME..."
  local secret
  secret="$(get_secret "$1")"

  # Decode/format secret
  if [ -n "$encoder" ]; then
    secret="$("$encoder"'Decode' "$secret")"
  fi
  if [ -n "$formatter" ]; then
    secret="$("$formatter"'Display' "$secret")"
  fi

  echo "$secret"
}

parse_options() {
  # -o is for short options like -v
  # -l is for long options with double dash like --version
  # -a is for long options with single dash like -version
  long="help,version,verbose,tenant::,subscription::,vault::,editor::,base64,urlencode,format::,extension::"
  short="hVt::s::v::E::bu"
  options="$(getopt -l "$long" -o "$short" -a -q -- "$@")"

  # set --:
  # If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters
  # are set to the arguments, even if some of them begin with a ‘-’.
  eval set -- "$options"

  while true; do
    case $1 in
    -h | --help)
      show_help
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
      encoder='base64'
      ;;
    -u | --urlencode)
      encoder='url'
      ;;
    -f | --format)
      shift
      case $1 in
      json)
        formatter="$1"
        extension=".$1"
        ;;
      ya?ml)
        formatter="$1"
        extension=".yml"
        ;;
      *)
        log_error "formatter unknown: $1"
        exit 1
        ;;
      esac
      ;;
    -E | --editor)
      shift
      EDITOR="$1"
      ;;
    -e | --extension)
      shift
      extensionPriority=".$1"
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
}

main() {
  local version='1.1.0'
  verbose=0
  encoder=''
  formatter=''
  extension=''

  # shellcheck disable=SC2068
  parse_options $@

  case $1 in
  h | help)
    show_help
    ;;
  v | version)
    echo "$version"
    ;;
  r | recover)
    shift
    verify_runtime "$1"
    az_login
    recover_secret "$1"
    ;;
  d | delete)
    shift
    verify_runtime "$1"
    az_login
    delete_secret "$1"
    ;;
  c | create)
    shift
    verify_runtime "$1"
    az_login
    create_secret "$1"
    ;;
  p | print)
    shift
    verify_runtime "$1"
    az_login
    print_secret "$1"
    ;;
  m | modify)
    shift
    verify_runtime "$1"
    az_login
    modify_secret "$1"
    ;;
  *)
    # Modify is the default action
    az_login
    verify_runtime "$1"
    modify_secret "$1"
    ;;
  esac
}

# Allow script to receive secret/value from STDIN
if ! test -t 0; then
  input=$(cat -)
fi

# shellcheck disable=2068
main $@ "${input:-}"
