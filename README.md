# gitea-runner-custom-image

Image Docker personnalisée pour exécuter le runner Gitea avec un utilisateur non privilégié `gitea-runner`.

## Contenu

- Base `ubuntu:latest`.
- Téléchargement hors `docker build` du dernier binaire Linux publié par `gitea/runner` via `scripts/download-gitea-runner.sh`, puis copie dans l'image avec `COPY`.
- Sélection automatique du binaire pré-téléchargé `amd64` ou `arm64` via BuildKit (`TARGETARCH`).
- Vérification du checksum SHA-256 fourni par la release Gitea.
- Exécution par défaut sous l'utilisateur non-root `gitea-runner` (`UID/GID 10001`).
- Binaire installé dans `/home/gitea-runner/bin/act_runner`.
- Répertoire de travail et volume de données sur `/home/gitea-runner/data`, afin de faciliter un lancement avec un système de fichiers racine en lecture seule.

## Build local

Téléchargez d'abord les binaires à placer dans le contexte Docker :

```bash
./scripts/download-gitea-runner.sh
```

Puis lancez le build multi-architecture :

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t gitea-runner-custom:latest .
```

Pour figer une version précise au moment du téléchargement :

```bash
RUNNER_VERSION=v1.0.0 ./scripts/download-gitea-runner.sh
docker buildx build --platform linux/amd64,linux/arm64 -t gitea-runner-custom:1.0.0 .
```

## Exécution

Par défaut, le conteneur lance :

```bash
/home/gitea-runner/bin/act_runner daemon
```

Exemple :

```bash
docker run --rm \
  --read-only \
  --security-opt no-new-privileges:true \
  --cap-drop ALL \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  -v gitea-runner-data:/home/gitea-runner/data \
  gitea-runner-custom:latest
```

> Le runner Gitea peut nécessiter des accès supplémentaires selon l'exécuteur configuré (par exemple un socket Docker ou un moteur compatible). N'ajoutez ces permissions qu'au cas par cas.

## GitHub Actions

Le workflow `.github/workflows/build-image.yml` télécharge les binaires `amd64` et `arm64` avant le build, puis construit l'image multi-architecture `linux/amd64` et `linux/arm64` sur `ubuntu-latest`.

- Pull requests : build uniquement.
- Branches et tags : build et push vers `ghcr.io/<owner>/gitea-runner-custom`.
