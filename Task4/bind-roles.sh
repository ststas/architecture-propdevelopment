#!/usr/bin/env bash
# Связывает роли из create-roles.sh с группами пользователей.
# Привязки делаются на группы (Group), а не на конкретных пользователей —
# группа каждого пользователя зашита в его сертификат полем O= (см. create-users.sh).
#
# Требует поднятого кластера и уже выполненного create-roles.sh.
# Порядок запуска скриптов: create-roles.sh -> create-users.sh -> bind-roles.sh
set -euo pipefail

echo "== cluster-viewer -> бизнес-аналитики, владельцы продукта, менеджеры, ИБ =="
kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-viewer-binding
subjects:
  - kind: Group
    name: business-analysts
    apiGroup: rbac.authorization.k8s.io
  - kind: Group
    name: product-owners
    apiGroup: rbac.authorization.k8s.io
  - kind: Group
    name: managers
    apiGroup: rbac.authorization.k8s.io
  - kind: Group
    name: security-officer
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-viewer
  apiGroup: rbac.authorization.k8s.io
EOF

echo "== cluster-configurator -> инженеры по эксплуатации =="
kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-configurator-binding
subjects:
  - kind: Group
    name: ops-engineers
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-configurator
  apiGroup: rbac.authorization.k8s.io
EOF

echo "== secrets-admin -> DevOps-инженеры =="
kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: secrets-admin-binding
subjects:
  - kind: Group
    name: devops
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secrets-admin
  apiGroup: rbac.authorization.k8s.io
EOF

echo "== domain-developer -> отдельная группа разработчиков на каждый домен-namespace =="
# namespace:группа — без ассоциативных массивов, т.к. системный /bin/bash на macOS (3.2)
# их не поддерживает (declare -A появился в bash 4.0).
DOMAIN_GROUPS=(
  "sales:devs-sales"
  "jku:devs-jku"
  "finance:devs-finance"
  "data:devs-data"
)

for entry in "${DOMAIN_GROUPS[@]}"; do
  ns="${entry%%:*}"
  group="${entry##*:}"
  kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: domain-developer-binding
  namespace: ${ns}
subjects:
  - kind: Group
    name: ${group}
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: domain-developer
  apiGroup: rbac.authorization.k8s.io
EOF
done

echo "Готово: биндинги ролей на группы созданы."
