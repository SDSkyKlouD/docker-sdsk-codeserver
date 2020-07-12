### docker-sdsk-codeserver
### code-server Docker image (customized by/for SD SkyKlouD)

# Based on latest Ubuntu LTS
FROM ubuntu:latest

# Upgrade existing packages
RUN apt-get update -y; \
    apt-get upgrade -y; \
    apt-get install -f -y

# Install common packages
RUN apt-get install --no-install-recommends -y \
    bash \
    ca-certificates \
    curl \
    wget \
    dumb-init \
    git \
    sudo \
    build-essential \
    gpg \
    apt-transport-https \
    openssl \
    bsdtar \
    locales \
    net-tools \
    util-linux

# Install Python
RUN apt-get install --no-install-recommends -y \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-pylint-common

# Install .NET Core SDK
RUN wget "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" -O /tmp/packages-microsoft-prod.deb; \
    dpkg -i /tmp/packages-microsoft-prod.deb; \
    apt-get update -y

RUN apt-get install --no-install-recommends -y \
    dotnet-sdk-3.1

# Install Node.js LTS
RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash -; \
    apt-get update -y

RUN apt-get install --no-install-recommends -y \
    nodejs

# APT & /tmp cleanup
RUN apt-get clean -y && rm -rf /var/lib/apt/lists/*
RUN rm -rf /tmp/*

# Install code-server
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
RUN localedef -i ko_KR -c -f UTF-8 -A /usr/share/locale/locale.alias ko_KR.UTF-8
ENV LANG ko_KR.utf8

ENV CODE_VERSION=$(curl -sL https://api.github.com/repos/cdr/code-server/releases/latest | grep '"name"' | head -1 | awk -F '[:]' '{print $2}' | sed -e 's/"//g' | sed -e 's/,//g' | sed -e 's/ //g' | sed -e 's/\r//g')
RUN curl -sL "https://github.com/cdr/code-server/releases/download/${CODE_VERSION}/code-server-${CODE_VERSION}-linux-x86_64.tar.gz" | tar --strip-components=1 -zx -C /usr/local/bin code-server-${CODE_VERSION}-linux-x86_64/code-server

# Setup code-server
RUN groupadd -r coder; \
    useradd -m -r coder -g coder -s /bin/bash; \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
USER coder
WORKDIR /home/coder
RUN chown -R coder:coder ~/
RUN mkdir -p ~/projects

ENV DOTNET_CLI_TELEMETRY_OPTOUT "true"
ENV PATH "${PATH}:/usr/share/dotnet"

ENV DISABLE_TELEMETRY true
ENV VSCODE_USER "~/.local/share/code-server/User"
ENV VSCODE_EXTENSIONS "~/.local/share/code-server/extensions"
RUN mkdir -p ${VSCODE_USER}
COPY --chown=coder:coder settings.json ~/.local/share/code-server/User/

EXPOSE 8080

ENTRYPOINT ["dumb-init", "--"]
CMd ["code-server", "/home/coder/projects", "--bind-addr=0.0.0.0:8080", "--disable-telemetry"]


### BIND
# (required) [host project folder] -> /home/coder/projects
# (recommended) [host vscode conf folder] -> /home/coder/.local/share/code-server