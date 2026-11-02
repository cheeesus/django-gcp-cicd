# Formation DevOps : Django, CI/CD et Google Cloud

Ce dépôt est un projet d’apprentissage pour mettre en pratique l’intégration continue et le déploiement continu d’une application Django conteneurisée sur Google Cloud Platform (GCP).

Le projet sert surtout de support aux expérimentations DevOps : l’application Django est encore un squelette, pas un produit complet.

## Technologies

- Python et Django
- Docker et Docker Compose
- GitHub Actions pour la CI/CD
- Google Cloud Workload Identity Federation pour l’authentification sans clé de compte de service stockée dans GitHub
- Artifact Registry pour stocker l’image Docker
- Cloud Run pour exécuter l’application
- PostgreSQL

## État actuel du projet

- Le projet Django expose actuellement l’interface d’administration à `/admin/` ; il ne contient pas encore de fonctionnalité métier.
- Le test existant vérifie une addition Python élémentaire. Il sert de premier contrôle dans le workflow CI, mais ne couvre pas encore le comportement Django.
- Le workflow de déploiement est déclenché à chaque `push`. En l’état, cela inclut donc les déploiements vers l’environnement configuré comme production.

## Lancer en local

Prérequis : Python 3.10 ou plus récent, [uv](https://docs.astral.sh/uv/) et Docker.

Installer les dépendances et lancer PostgreSQL :

```bash
uv sync --frozen
docker compose up -d postgres
```

Dans le même terminal, configurer les paramètres de développement, appliquer les migrations puis démarrer Django :

```bash
export SECRET_KEY="cle-locale-a-remplacer"
export APP_ENVIRONMENT="development"
export DB_URL="postgres://root:root@localhost:5432/devops"
uv run python src/manage.py migrate
uv run python src/manage.py runserver
```

L’application est ensuite disponible sur `http://127.0.0.1:8000/`. L’interface d’administration se trouve sur `/admin/`.

Lancer les tests :

```bash
uv run pytest
```

## CI/CD sur GitHub Actions

Deux workflows sont présents dans `.github/workflows/` :

1. `devops_api.yml` installe les dépendances avec le lockfile, puis exécute `pytest` à chaque `push`.
2. `prod-deploy.yml` appelle le workflow réutilisable `deployment.yaml`, qui construit l’image Docker, la publie dans Artifact Registry et la déploie sur Cloud Run.

Le déploiement s’authentifie à Google Cloud avec Workload Identity Federation. Il faut configurer dans les paramètres GitHub du dépôt les secrets et variables référencés par les workflows :

- Secrets : `WIF_PROVIDER`, `WIF_SERVICE_ACCOUNT`
- Variables : `REGION`, `GCP_PROJECT_ID`, `ARTIFACT_REPO`, `SERVICE_NAME`, `service_name`, `CLOUD_RUN_SA`, `region`

Les valeurs doivent correspondre aux ressources GCP réellement créées : fournisseur Workload Identity, compte de service, dépôt Artifact Registry et service Cloud Run. Ne publiez jamais de clé JSON de compte de service dans le dépôt ; le workflow utilise l’authentification fédérée à la place.

## Docker Compose

Le fichier Compose définit un service PostgreSQL et un service Django. Pour le lancement Django en local décrit plus haut, seul le service `postgres` est utilisé.

Le service Django de Compose n’est pas encore entièrement raccordé à PostgreSQL : les paramètres actuels définissent `DB_HOST`, alors que Django lit `DB_URL`. Il faut donc fournir une `DB_URL` adaptée au réseau Compose (avec `postgres` comme hôte) avant de lancer les deux services ensemble.

## Sécurité

Les identifiants `root` / `root` et `SECRET_KEY="secret"` dans `docker-compose.yml` sont des valeurs de démonstration réservées au développement. Ne les réutilisez pas en production. La configuration de production doit utiliser des secrets gérés hors du dépôt, ainsi qu’une valeur `SECRET_KEY` forte et privée.

Les fichiers locaux `.env`, `.envrc` et `.venv` sont ignorés par Git. Vérifiez tout de même les changements avec `git status` avant chaque publication et ne commitez jamais de fichier contenant des identifiants ou des secrets.
