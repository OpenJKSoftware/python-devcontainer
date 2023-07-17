# Basic Python package with Company CAs and sudo User
ARG USERNAME=ContainerUser
ARG PYTHONVERSION=3.11

FROM python:${PYTHONVERSION}-bullseye as python-base
ARG USERNAME
LABEL org.opencontainers.image.source=https://github.com/OpenJKSoftware/python-devcontainer

ENV POETRY_VERSION=1.5.1
ENV PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=on

# Switch sh With Bash
RUN set -x; \
    rm /bin/sh && ln -s /bin/bash /bin/sh

# Install Base Reqs
RUN set -x; \
    echo "deb http://deb.debian.org/debian bullseye-backports main" >/etc/apt/sources.list.d/bullseye-backports.list \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    build-essential \
    apt-transport-https \
    ca-certificates \
    iputils-ping \
    rsync \
    expect \
    git/bullseye-backports \
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
    && useradd --shell /usr/bin/zsh --create-home ${USERNAME} \
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

# Install Poetry as Root
RUN pip install -U pip setuptools poetry==$POETRY_VERSION && poetry config virtualenvs.create false

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
# Poetry install for user
# We alias poetry to sudo poetry to deal with permissions errors, when poetry tries to write to site packages
RUN set -x; \
    echo "alias poetry='sudo poetry'" >> /home/${USERNAME}/.zshrc \
    && echo "alias poetry='sudo poetry'" >> /home/${USERNAME}/.bashrc \
    && poetry config virtualenvs.create false \
    && poetry config installer.max-workers 10 \
    && sudo poetry self add poetry-bumpversion \
    && poetry completions bash | sudo tee /etc/bash_completion.d/poetry.bash-completion > /dev/null \
    && mkdir -p ./.oh-my-zsh/plugins/poetry \
    && poetry completions zsh > ./.oh-my-zsh/plugins/poetry/_poetry

RUN sudo rm -rf {./*,/tmp/*,/var/cache/apt/*,/var/lib/apt/lists/*}
ENTRYPOINT [ "/usr/bin/zsh" ]
