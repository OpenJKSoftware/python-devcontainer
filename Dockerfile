# syntax = docker/dockerfile:1.14
# Basic Python package with Company CAs and sudo User
ARG USERNAME=ContainerUser
ARG PYTHONVERSION=3.11

# ############################################################################################################
FROM debian:bookworm AS python-base

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
RUN /tmp/install_base_deps.sh

# Create User and setup environment
RUN useradd --shell /usr/bin/zsh --create-home ${USERNAME} -u 1000 \
    && mkdir -pm 700 /root/.ssh \
    && echo "alias vi=nvim" > /etc/profile.d/vim_nvim.sh \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
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

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
ENV UV_CACHE_DIR=/var/cache/uv \
    UV_PYTHON_CACHE_DIR=/var/cache/uv/python \
    UV_LINK_MODE=copy
RUN set -x; mkdir -p $UV_CACHE_DIR && mkdir -p $UV_PYTHON_CACHE_DIR
RUN --mount=type=cache,target=/var/cache/uv,sharing=locked uv python install ${PYTHONVERSION} --default

RUN apt autoremove --purge -y && apt clean -y

# Non Root User
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Oh-My-Zsh user config
RUN set -x ; \
    bash -c "mkdir -p {.zfunc,.commandhistory}" \
    && sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
COPY --chown=${USERNAME}:${USERNAME} .zshrc .zshrc

ENTRYPOINT [ "/usr/bin/zsh" ]
