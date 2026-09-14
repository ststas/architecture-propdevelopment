# Таблица ролей RBAC для кластера Kubernetes PropDevelopment

Namespace кластера разбиты по доменам компании: `sales` (продажи), `jku` (ЖКУ), `finance` (финансы), `data` (данные).

| Роль | Права роли | Группы пользователей |
| --- | --- | --- |
| `cluster-viewer` | Только просмотр (`get`, `list`, `watch`) ресурсов кластера во всех namespace: pods, deployments, services, configmaps, namespaces. Без доступа к Secrets. | Бизнес-аналитики, владельцы продукта, менеджеры, специалист по ИБ (техническая видимость кластера без права что-либо менять) |
| `cluster-configurator` | Настройка рабочей нагрузки во всех namespace: `get/list/watch/create/update/patch/delete` на pods, deployments, services, configmaps. Без доступа к Secrets и без права менять RBAC-объекты. | Инженеры по эксплуатации |
| `secrets-admin` | Всё из `cluster-configurator` плюс полный доступ (`get/list/watch/create/update/patch/delete`) к Secrets во всех namespace. Привилегированная роль. | DevOps-инженеры |
| `domain-developer` | Полное управление рабочей нагрузкой (`get/list/watch/create/update/patch/delete` на pods, deployments, services, configmaps) **только в своём namespace**. Без доступа к Secrets. Описана один раз как `ClusterRole`-шаблон и переиспользуется через отдельный `RoleBinding` на каждый домен-namespace. | Разработчики домена — по своей группе на каждый namespace: `devs-sales` (namespace `sales`), `devs-jku` (namespace `jku`), `devs-finance` (namespace `finance`), `devs-data` (namespace `data`) |
