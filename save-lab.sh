#!/usr/bin/env bash
set -euo pipefail

mapfile -t containers < <(docker ps --filter "name=^/clab-junos-lab-" --format '{{.Names}}' | sort)

if [ "${#containers[@]}" -eq 0 ]; then
  echo "No running clab-junos-lab-* containers found." >&2
  exit 1
fi

for container in "${containers[@]}"; do
  node="${container#clab-junos-lab-}"
  echo "Saving ${node} (${container})..."
  docker exec "$container" cli -c "show configuration" > "configs/${node}.conf"
  docker exec "$container" cli -c "show configuration | display set" > "backups/${node}.set"

  grep -vE '^\s*encrypted-password\b' "configs/${node}.conf" > "sanitized_configs/${node}.conf"
  grep -v 'set system root-authentication encrypted-password' "backups/${node}.set" > "sanitized_backups/${node}.set"
done

echo "Saved ${#containers[@]} node(s) to configs/, backups/, sanitized_configs/, and sanitized_backups/."
