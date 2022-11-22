ARG USERNAME=ContainerUser
ARG PYTHONVERSION=3.8

# Basic Python package with Company CAs and sudo User
FROM python:$PYTHONVERSION-buster
LABEL org.opencontainers.image.source=https://github.com/OpenJKSoftware/python-devcontainer

ARG USERNAME

# Switch sh With Bash and enable Apt Cache
RUN set -x; \
    rm /bin/sh && ln -s /bin/bash /bin/sh \
    && rm -f /etc/apt/apt.conf.d/docker-clear

# Install Base Reqs
RUN set -x; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    apt-transport-https \
    rsync \
    expect \
    git \
    openssh-client  \
    manpages \
    less \
    zsh \
    fonts-powerline \
    && useradd -ms /usr/bin/zsh ${USERNAME} \
    && mkdir -p /root/.ssh \
    && chmod 700 /root/.ssh/

RUN set -x; \
    apt-get install locales -y --no-install-recommends \
    && echo "LC_ALL=en_US.UTF-8" >> /etc/environment \
    && echo "LANG=en_US.utf-8" >> /etc/environment \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
    && locale-gen en_US.UTF-8

COPY known_hosts /root/.ssh/known_hosts

RUN set -x; \
    apt-get -y install --no-install-recommends sudo \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && rm -rf /var/lib/apt/lists/*

ENV PIP_CACHE_DIR=/var/cache/buildkit/pip
RUN set -x; \
    mkdir -p $PIP_CACHE_DIR \
    && chown -R ${USERNAME}:${USERNAME} $PIP_CACHE_DIR

USER ${USERNAME}
WORKDIR /home/${USERNAME}
COPY --chown=${USERNAME}:${USERNAME} known_hosts .ssh/known_hosts
RUN set -x ; \
    mkdir -p .zfunc \
    && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
COPY --chown=${USERNAME}:${USERNAME} .zshrc .zshrc

ENV PATH="/home/${USERNAME}/.local/bin/:${PATH}"
RUN set -x ; \
    python3 -m pip install --user pipx \
    && python3 -m pipx ensurepath \
    && pipx install poetry \
    && poetry completions bash | sudo tee /etc/bash_completion.d/poetry.bash-completion > /dev/null \
    && poetry completions zsh > .zfunc/_poetry \
    && poetry self add poetry-bumpversion
ENTRYPOINT [ "/usr/bin/zsh" ]
