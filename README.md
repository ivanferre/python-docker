# python-docker

This is a very simple project to demonstrate building a Docker image from a Python application.

Following [Build your Python image](https://docs.docker.com/language/python/build-images/). Actually, [Docker Python](https://docs.docker.com/language/python/).

## Using Docker Swarm Secrets

<https://spacelift.io/blog/docker-secrets#using-docker-swarm-secrets>

Create a swarm:

    docker swarm init

Create a local file to store the secret value:

    echo foobar > password.txt

Create the Docker secret object. The command takes two arguments: the secret’s name, and the path to the file that contains its value:

    docker secret create mysql_secret_password password.txt

You can also create secrets from the terminal input stream. Doing so prevents secrets being saved to files on your machine.

    echo foobar | docker secret create mysql_secret_password -

To start a service with a secret, use the `--secret` flag to immediately inject a named secret.

    docker service create --name mysql --secret mysql_root_password -e MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql_root_password mysql:8.0

As with Compose secrets, Swarm mounts the secret to `/run/secrets/<secret_name>` inside the container. This produces the path of `/run/secrets/mysql_root_password` in this example.

In practice, this service doesn’t need long-lived access to the secret. The container only needs to know the password once, during MySQL’s first-run initialization routine. You can update the service to detach the secret, preventing a compromised container process from accessing it:

    docker service update mysql --secret-rm mysql_root_password

And you can also attach a secret to an existing service:

    docker service update mysql --secret-add mysql_root_password

Secrets are mounted to `/run/secrets/<secret_name>` by default, but you can customize this using a more verbose variant of the `--secret` and `--secret-add` flags:

    docker service update mysql --secret-add source=password.txt,target=/etc/mysql/root_password

Running this command will mount your local `password.txt` file to `/etc/mysql/root_password` inside the container. This is useful when your application expects to read secret files from a specific path that can’t be changed.

You can list all the secrets you’ve created with the `docker secret ls` command, and delete a secret with `docker secret rm`. It isn’t possible to delete a secret that’s actively used by a service. Detach the secret from your services before you try to remove it.

### Referencing Swarm Secrets in Compose Files

You can reuse Swarm secrets in services managed by Docker Compose. Create the secret using docker secret create, then reference it within the services section of your `docker-compose.yml` file by setting the external field to `true`:

    version: "3"
    services:
    mysql:
        image: mysql:8.0
        environment:
        MYSQL_ROOT_PASSWORD_FILE: /run/secrets/mysql_root_password
        secrets:
        - mysql_root_password
    secrets:
    mysql_root_password:
        external: true

Compose will take the secret’s value from the swarm, instead of reading it from a local file.

### Dockerfile Secrets When You're Building Images

In addition to runtime container configuration, secret values can also be required by the Dockerfile instructions used to build your images. You might have to authenticate to a remote package registry ahead of an instruction that installs your project’s dependencies, for example.

Hardcoding these secrets into your Dockerfile is dangerous because they’ll be visible to anyone who can access your source control repository. It’s better practice to use Docker’s [build args feature](https://docs.docker.com/engine/reference/builder/#arg) to declare variables that must be set when you run `docker build`.

The following Dockerfile installs npm packages from a custom registry that requires authentication. The `ARG NPM_AUTH_TOKEN` instruction defines a build arg that’s used to supply the authentication token:

    FROM node:18 AS build
    ARG NPM_AUTH_TOKEN

    COPY package.json package.json
    COPY package-lock.json package-lock.json
    RUN npm config set @example:registry <https://registry.example.com/> &&\
    npm config set -- '//registry.example.com/:_authToken' "${NPM_AUTH_TOKEN}" &&\
    npm install

Set the `--build-arg` flag to provide your auth token when you build the image:

    docker build --build-arg NPM_AUTH_TOKEN=foobar -t example-image:latest .

This ensures sensitive values used by your build instructions aren’t hardcoded into your [Dockerfile](https://spacelift.io/blog/dockerfile), or accidentally persisted to the container image’s filesystem.

## Best Practices for Docker Secrets

1. `.gitignore` all files that contain secrets – Mounting secrets into containers from local files carries the risk of those files being accidentally committed to your repository.
2. Add paths that will contain secrets to your `.gitignore` file to prevent `git add .` from inadvertently staging sensitive values.
3. Make apps always read secrets from the filesystem, instead of environment variables, to prevent user mistakes and shortcuts.
4. Ensure secrets are used for all sensitive values. A secret is anything that could be valuable to an attacker, or which might expose other data – secrets shouldn’t be confined to passwords and certificates.

Managing secrets independently of your containers also prepares you for other ecosystem tools where secrets are treated as first-class objects, such as [Kubernetes secrets](https://spacelift.io/blog/kubernetes-secrets).

## Swarm

    $ docker swarm init
    Swarm initialized: current node (7stcac5oys3adkcnegyp0ocyz) is now a manager.
    To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-201xkxgkth4bx4b8vw4ubrwudmy4q3zswy7gmjlvqwsjwyccy8-2y7a0bfzuodsyi7tex8hqba7b 192.168.65.4:2377

    To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

## TODO

1. [Manage sensitive data with Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
1. [Deploying Docker containers on ECS](https://docs.docker.com/cloud/ecs-integration/)
