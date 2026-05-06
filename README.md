# gitea-runner-custom-image

Image Docker personnalisée pour exécuter le runner Gitea avec un utilisateur non privilégié `gitea-runner`.

## Contenu

- Base `ubuntu:latest`.
- Téléchargement au build du dernier binaire Linux publié par `gitea/runner` lorsque `RUNNER_VERSION=latest`.
- Sélection automatique du binaire `amd64` ou `arm64` via BuildKit (`TARGETARCH`).
- Vérification du checksum SHA-256 fourni par la release Gitea.
- Exécution par défaut sous l'utilisateur non-root `gitea-runner` (`UID/GID 10001`).
- Binaire installé dans `/home/gitea-runner/bin/act_runner`.
- Répertoire de travail et volume de données sur `/home/gitea-runner/data`, afin de faciliter un lancement avec un système de fichiers racine en lecture seule.

## Build local

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t gitea-runner-custom:latest .
```

Pour figer une version précise :

```bash
docker build --build-arg RUNNER_VERSION=v1.0.0 -t gitea-runner-custom:1.0.0 .
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

Le workflow `.github/workflows/build-image.yml` construit l'image multi-architecture `linux/amd64` et `linux/arm64` sur `ubuntu-latest`.

- Pull requests : build uniquement.
- Branches et tags : build et push vers `ghcr.io/<owner>/gitea-runner-custom`.
