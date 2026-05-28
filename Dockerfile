# syntax = docker/dockerfile:1.14
# Basic Python package with Company CAs and sudo User
ARG USERNAME=ContainerUser
ARG PYTHONVERSION=3.11
ARG DEBIANVERSION=bookworm

# ############################################################################################################
FROM debian:${DEBIANVERSION} AS base

ENV PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1 \
    PIP_CACHE_DIR=/var/cache/pip
RUN mkdir -p $PIP_CACHE_DIR

ARG USERNAME
LABEL org.opencontainers.image.source=https://github.com/OpenJKSoftware/python-devcontainer

# Ensure Apt cache is kept between builds
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Install Base Reqs
COPY scripts/install_base_deps.sh /tmp/
RUN --mount=target=/var/cache/apt,type=cache,sharing=locked   \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked set -x; /tmp/install_base_deps.sh

# Create User and setup environment
RUN useradd --shell /usr/bin/zsh --create-home ${USERNAME} -u 1000 \
    && mkdir -pm 700 /root/.ssh \
    && echo "alias vi=nvim" > /etc/profile.d/vim_nvim.sh \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && chown ${USERNAME}:${USERNAME} /var/cache
ENV EDITOR=nvim

# Fix Locale issues
RUN --mount=target=/var/cache/apt,type=cache,sharing=locked \
    --mount=target=/var/lib/apt/lists,type=cache,sharing=locked set -x; \
    apt update && apt-get install locales -y --no-install-recommends \
    && echo "LC_ALL=en_US.UTF-8" >> /etc/environment \
    && echo "LANG=en_US.utf-8" >> /etc/environment \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "LANG=en_US.UTF-8" > /etc/locale.conf \
    && locale-gen en_US.UTF-8

# Known hosts for Root and User
COPY known_hosts /root/.ssh/known_hosts
COPY --chown=${USERNAME}:${USERNAME} known_hosts /home/${USERNAME}/.ssh/known_hosts

# Non Root User
USER ${USERNAME}
WORKDIR /home/${USERNAME}
ENV PATH="/home/${USERNAME}/.local/bin:${PATH}"

# Starship user config
RUN set -x ; \
    bash -c "mkdir -p {.zfunc,.commandhistory,.config,.local/bin}" \
    && curl -sS https://starship.rs/install.sh | sh -s -- -y -b /home/${USERNAME}/.local/bin
COPY --chown=${USERNAME}:${USERNAME} .zshrc .zshrc
COPY --chown=${USERNAME}:${USERNAME} starship.toml /home/${USERNAME}/.config/starship.toml

ENTRYPOINT [ "/usr/bin/zsh" ]

FROM base AS python-devcontainer

# Install uv
ARG PYTHONVERSION
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
ENV UV_CACHE_DIR=/var/cache/uv \
    UV_PYTHON_CACHE_DIR=/var/cache/uv/python \
    UV_LINK_MODE=copy

RUN --mount=type=cache,target=$UV_CACHE_DIR,uid=1000 set -x; uv python install ${PYTHONVERSION} --default && uv python pin --global ${PYTHONVERSION}
