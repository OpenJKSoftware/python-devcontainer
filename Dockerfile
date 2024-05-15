# Basic Python package with Company CAs and sudo User
ARG USERNAME=ContainerUser
ARG PYTHONVERSION=3.11

FROM python:${PYTHONVERSION}-bullseye as python-base

ENV POETRY_VERSION=1.8.2
ENV POETRY_CACHE_DIR=/var/cache/poetry \
    POETRY_HOME=/opt/poetry \
    PATH=/opt/poetry/bin:${PATH}\
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_CACHE_DIR=/var/cache/buildkit/pip
RUN mkdir -p $PIP_CACHE_DIR $POETRY_CACHE_DIR


FROM python-base as poetry-base

# Poetry install
RUN set -x; \
    curl -sSL https://install.python-poetry.org | python3 - \
    && poetry self add poetry-bumpversion

FROM python-base as devcontainer
ARG USERNAME
LABEL org.opencontainers.image.source=https://github.com/OpenJKSoftware/python-devcontainer

# Switch sh With Bash
RUN set -x; \
    rm /bin/sh && ln -s /bin/bash /bin/sh

# Install Base Reqs
RUN set -x; \
    apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    build-essential \
    apt-transport-https \
    ca-certificates \
    iputils-ping \
    rsync \
    expect \
    git\
    openssh-client  \
    manpages \
    less \
    zsh \
    fonts-powerline \
    htop \
    fzf \
    neovim \
    pv \
    jq \
    lsb-release \
    && useradd --shell /usr/bin/zsh --create-home ${USERNAME} -u 1000 \
    && mkdir -p /root/.ssh \
    && chmod 700 /root/.ssh/ \
    && echo "alias vi=nvim" > /etc/profile.d/vim_nvim.sh
ENV EDITOR=nvim

# Fix Locale issues
RUN set -x; \
    apt-get install locales -y --no-install-recommends \
    && echo "LC_ALL=en_US.UTF-8" >> /etc/environment \
    && echo "LANG=en_US.utf-8" >> /etc/environment \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
    && locale-gen en_US.UTF-8

# Known hosts for Root and User
COPY known_hosts /root/.ssh/known_hosts
COPY --chown=${USERNAME}:${USERNAME} known_hosts /home/${USERNAME}/.ssh/known_hosts

# Sudo Support
RUN set -x; \
    apt-get -y install --no-install-recommends sudo \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Copy Poetry from other stage and add to path
COPY --from=poetry-base --chown=${USERNAME}:${USERNAME} ${POETRY_HOME} ${POETRY_HOME}
RUN chown -R ${USERNAME}:${USERNAME} $PIP_CACHE_DIR $POETRY_CACHE_DIR

# Non Root User
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Oh-My-Zsh user config
RUN set -x ; \
    mkdir -p {.zfunc,.commandhistory} \
    && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
COPY --chown=${USERNAME}:${USERNAME} .zshrc .zshrc

# Poetry
ENV PATH="/home/${USERNAME}/.local/bin/:${PATH}"
RUN set -x ; \
    poetry completions bash | sudo tee /etc/bash_completion.d/poetry.bash-completion > /dev/null \
    && mkdir -p ./.oh-my-zsh/plugins/poetry \
    && poetry completions zsh > ./.oh-my-zsh/plugins/poetry/_poetry \
    && poetry config installer.max-workers 10

RUN sudo rm -rf {./*,/tmp/*,/var/cache/apt/*,/var/lib/apt/lists/*,$PIP_CACHE_DIR/*}
ENTRYPOINT [ "/usr/bin/zsh" ]
