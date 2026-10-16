#!/usr/bin/env bash
# Создаёт пользователей для демонстрации RBAC: генерирует ключ и CSR,
# подписывает сертификат через CA кластера Minikube и добавляет
# пользователя и контекст в kubeconfig. Группа пользователя (для RBAC)
# зашивается в сертификат полем O= в Subject.
#
# Пользователи для демонстрации (по одному на каждую привилегированную/
# базовую/доменную роль из rbac_table.md):
#   ivan-devops    -> группа devops         -> роль secrets-admin
#   olga-analyst   -> группа business-analysts -> роль cluster-viewer
#   anna-developer -> группа devs-sales     -> роль domain-developer (namespace sales)
#
# Требует поднятого кластера: minikube start
# Порядок запуска скриптов: create-roles.sh -> create-users.sh -> bind-roles.sh
set -euo pipefail

CA_CRT="${HOME}/.minikube/ca.crt"
CA_KEY="${HOME}/.minikube/ca.key"
CLUSTER_NAME="$(kubectl config view -o jsonpath='{.clusters[0].name}')"
WORKDIR="$(mktemp -d)"

if [[ ! -f "$CA_CRT" || ! -f "$CA_KEY" ]]; then
  echo "Не найден CA кластера Minikube ($CA_CRT / $CA_KEY)." >&2
  echo "Убедитесь, что кластер поднят через 'minikube start'." >&2
  exit 1
fi

# username:group
USERS=(
  "ivan-devops:devops"
  "olga-analyst:business-analysts"
  "anna-developer:devs-sales"
)

for entry in "${USERS[@]}"; do
  user="${entry%%:*}"
  group="${entry##*:}"

  echo "== Создание пользователя ${user} (группа ${group}) =="

  openssl genrsa -out "${WORKDIR}/${user}.key" 2048 >/dev/null 2>&1

  openssl req -new \
    -key "${WORKDIR}/${user}.key" \
    -out "${WORKDIR}/${user}.csr" \
    -subj "/CN=${user}/O=${group}"

  openssl x509 -req \
    -in "${WORKDIR}/${user}.csr" \
    -CA "$CA_CRT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out "${WORKDIR}/${user}.crt" \
    -days 500 \
    -sha256 >/dev/null 2>&1

  kubectl config set-credentials "$user" \
    --client-certificate="${WORKDIR}/${user}.crt" \
    --client-key="${WORKDIR}/${user}.key" \
    --embed-certs=true >/dev/null

  kubectl config set-context "$user" \
    --cluster="$CLUSTER_NAME" \
    --user="$user" >/dev/null

  echo "   Пользователь ${user} добавлен в kubeconfig. Проверить права:"
  echo "     kubectl --context=${user} auth can-i --list"
done

rm -rf "$WORKDIR"

echo "Готово: пользователи созданы и добавлены в kubeconfig (ivan-devops, olga-analyst, anna-developer)."
