### docker-sdsk-codeserver
### code-server Docker image (customized by/for SD SkyKlouD)
## Dockerfile referenced from https://github.com/monostream/code-server

# Based on latest Ubuntu LTS
FROM ubuntu:latest

# Upgrade existing packages
RUN apt-get update -y; \
    apt-get install -f -y; \
    apt-get upgrade -y

# Workaround for tzdata during build time
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install common packages
RUN apt-get install --no-install-recommends -y \
    apt-utils \
    bash \
    tar \
    ca-certificates \
    curl \
    wget \
    dumb-init \
    git \
    patch \
    make \
    sudo \
    build-essential \
    gpg \
    gpg-agent \
    apt-transport-https \
    openssl \
    locales \
    util-linux \
    pkg-config \
    lsb-release \
    tzdata

# Install Python
RUN apt-get install --no-install-recommends -y \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-pylint-common

# Install DPKG-dev
RUN apt-get install --no-install-recommends -y \
    dpkg-dev

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
ENV LANG=ko_KR.utf8

RUN \
    CODE_VERSION=$(curl -sL https://api.github.com/repos/cdr/code-server/releases/latest | grep '"name"' | head -1 | awk -F '[:]' '{print $2}' | sed -e 's/"//g' | sed -e 's/,//g' | sed -e 's/ //g' | sed -e 's/\r//g') \
    && CODE_VERSION_WITHOUT_V=$(echo $CODE_VERSION | sed -e 's/v//g') \
    && curl -fsL "https://github.com/cdr/code-server/releases/download/${CODE_VERSION}/code-server-${CODE_VERSION_WITHOUT_V}-linux-amd64.tar.gz" | tar -zx -C /usr/local/bin \
    && mv /usr/local/bin/code-server-${CODE_VERSION_WITHOUT_V}-linux-amd64 /usr/local/bin/code-server \
    && ln -s /usr/local/bin/code-server/bin/code-server /usr/bin/code-server

# Setup code-server
RUN groupadd -r coder; \
    useradd -m -r coder -g coder -s /bin/bash; \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
USER coder
WORKDIR /home/coder
RUN chown -R coder:coder ~/
RUN mkdir -p ~/projects

ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV PATH="${PATH}:/usr/share/dotnet"

ENV DISABLE_TELEMETRY=true
ENV CODE_USER="~/.local/share/code-server/User"
ENV CODE_EXTENSIONS="~/.local/share/code-server/extensions"
RUN mkdir -p ${CODE_USER}
COPY --chown=coder:coder settings.json ${CODE_USER}/

# Install extensions (meaningless when bind directory)
RUN code-server --install-extension ms-ceintl.vscode-language-pack-ko
RUN code-server --install-extension pkief.material-icon-theme
RUN code-server --install-extension ms-dotnettools.csharp
RUN code-server --install-extension ms-python.python
RUN code-server --install-extension ms-vscode.typescript-javascript-grammar
RUN code-server --install-extension christian-kohler.npm-intellisense
RUN code-server --install-extension eamodio.gitlens

# FINAL
EXPOSE 8080

ENTRYPOINT ["dumb-init", "/usr/bin/code-server", "/home/coder/projects", "--bind-addr=0.0.0.0:8080", "--disable-telemetry"]


### BIND
# (required) [host project folder] -> /home/coder/projects
# (recommended) [host vscode conf folder] -> /home/coder/.local/share/code-server
