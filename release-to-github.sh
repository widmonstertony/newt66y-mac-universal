#!/bin/zsh
set -euo pipefail

root_dir="${0:A:h}"
repo="widmonstertony/newt66y-mac-universal"
tag="v1.4.0"
release_name="小草 Mac 浏览器 v1.4.0"
asset="$root_dir/dist/NewT66y-Mac-Universal-v1.4.0.zip"
checksum="$root_dir/dist/SHA256SUMS.txt"
notes="$root_dir/release-notes-v1.4.0.md"

credential="$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill 2>/dev/null || true)"
github_token=""
while IFS='=' read -r key value; do
  if [[ "$key" == "password" ]]; then
    github_token="$value"
  fi
done <<< "$credential"
unset credential

if [[ -z "$github_token" ]]; then
  github_token="$(security find-generic-password \
    -s 'GitHub - https://api.github.com' \
    -a 'widmonstertony' \
    -w 2>/dev/null || true)"
fi

if [[ -z "$github_token" ]]; then
  print -u2 "GitHub credential helper and macOS Keychain did not return a token."
  exit 1
fi

api() {
  curl --fail-with-body --silent --show-error \
    --header "Authorization: Bearer ${github_token}" \
    --header 'Accept: application/vnd.github+json' \
    --header 'X-GitHub-Api-Version: 2022-11-28' \
    "$@"
}

release_json="$(api "https://api.github.com/repos/${repo}/releases/tags/${tag}" 2>/dev/null || true)"
release_id="$(printf '%s' "$release_json" | jq -r '.id // empty')"

if [[ -z "$release_id" ]]; then
  payload="$(jq -n \
    --arg tag "$tag" \
    --arg name "$release_name" \
    --rawfile body "$notes" \
    '{tag_name:$tag,target_commitish:"main",name:$name,body:$body,draft:false,prerelease:false,generate_release_notes:false}')"
  release_json="$(printf '%s' "$payload" | api \
    --request POST \
    --header 'Content-Type: application/json' \
    --data-binary @- \
    "https://api.github.com/repos/${repo}/releases")"
  release_id="$(printf '%s' "$release_json" | jq -r '.id')"
fi

upload_url="$(printf '%s' "$release_json" | jq -r '.upload_url' | sed 's/{.*$//')"
html_url="$(printf '%s' "$release_json" | jq -r '.html_url')"

for filename in "$(basename "$asset")" "$(basename "$checksum")"; do
  asset_id="$(api "https://api.github.com/repos/${repo}/releases/${release_id}/assets" | \
    jq -r --arg name "$filename" '.[] | select(.name == $name) | .id' | head -n 1)"
  if [[ -n "$asset_id" ]]; then
    api --request DELETE "https://api.github.com/repos/${repo}/releases/assets/${asset_id}" >/dev/null
  fi
done

api --request POST \
  --header 'Content-Type: application/zip' \
  --data-binary "@${asset}" \
  "${upload_url}?name=$(basename "$asset")" >/dev/null

api --request POST \
  --header 'Content-Type: text/plain' \
  --data-binary "@${checksum}" \
  "${upload_url}?name=$(basename "$checksum")" >/dev/null

unset github_token
print -r -- "$html_url"
