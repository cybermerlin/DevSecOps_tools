#!/usr/bin/env sh
set -eu


# ---------- JWT helpers (openssl + jq) ----------
# header
_jwt_header='{"alg":"HS256","typ":"JWT"}'
# payload (empty object, never expires)
_jwt_payload='{}'
# base64url encode without newline
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

_h=$(printf %s "$_jwt_header"  | b64url)
_p=$(printf %s "$_jwt_payload" | b64url)
# create signature (HMAC SHA-256)
_secret="${1:-mysupersecret}"   # same as CUBEJS_API_SECRET in .env
_sig=$(printf %s "${_h}.${_p}" | openssl dgst -sha256 -hmac "$_secret" -binary | b64url)

export _TOKEN="${_h}.${_p}.${_sig}"
echo "${_TOKEN}"
# ----------------------------------------------
