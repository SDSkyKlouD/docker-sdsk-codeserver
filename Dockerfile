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
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
RUN localedef -i ko_KR -c -f UTF-8 -A /usr/share/locale/locale.alias ko_KR.UTF-8

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
#RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash -; \
#    apt-get update -y

#RUN apt-get install --no-install-recommends -y \
#    nodejs

# Install code-server
RUN \
    CODE_VERSION=$(curl -sL https://api.github.com/repos/cdr/code-server/releases/latest | grep '"name"' | head -1 | awk -F '[:]' '{print $2}' | sed -e 's/"//g' | sed -e 's/,//g' | sed -e 's/ //g' | sed -e 's/\r//g') \
    && CODE_VERSION_WITHOUT_V=$(echo $CODE_VERSION | sed -e 's/v//g') \
    && curl -fsL "https://github.com/cdr/code-server/releases/download/${CODE_VERSION}/code-server-${CODE_VERSION_WITHOUT_V}-linux-amd64.tar.gz" | tar -zx -C /usr/local/bin \
    && mv /usr/local/bin/code-server-${CODE_VERSION_WITHOUT_V}-linux-amd64 /usr/local/bin/code-server \
    && ln -s /usr/local/bin/code-server/bin/code-server /usr/bin/code-server

# Install fixuid
RUN \
    FIXUID_VERSION=$(curl -sL https://api.github.com/repos/boxboat/fixuid/releases/latest | grep '"name"' | head -1 | awk -F '[:]' '{print $2}' | sed -e 's/"//g' | sed -e 's/,//g' | sed -e 's/ //g' | sed -e 's/\r//g') \
    && FIXUID_VERSION_WITHOUT_V=$(echo $FIXUID_VERSION | sed -e 's/v//g') \
    && USER=coder \
    && GROUP=coder \
    && curl -fsL "https://github.com/boxboat/fixuid/releases/download/${FIXUID_VERSION}/fixuid-${FIXUID_VERSION_WITHOUT_V}-linux-amd64.tar.gz" | tar -zx -C /usr/local/bin \
    && chown root:root /usr/local/bin/fixuid \
    && chmod 4755 /usr/local/bin/fixuid \
    && ln -s /usr/local/bin/fixuid /usr/bin/fixuid \
    && mkdir -p /etc/fixuid \
    && printf "user: $USER\ngroup: $GROUP\n" > /etc/fixuid/config.yml

# Install entrypoint.sh
COPY entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

# Setup code-server
RUN addgroup --gid 1000 coder \
    && adduser --uid 1000 --ingroup coder --home /home/coder --shell /bin/bash --disabled-password --gecos "" coder \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
USER coder:coder
WORKDIR /home/coder
RUN mkdir -p ~/projects

ENV LANG=ko_KR.utf8

ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DISABLE_TELEMETRY=true
ENV PATH="${PATH}:/usr/share/dotnet"

ENV CODE_DATA="/home/coder/.local/share/code-server"
ENV CODE_USER="${CODE_DATA}/User"
ENV CODE_EXTENSIONS="${CODE_DATA}/extensions"
RUN mkdir -p ${CODE_USER}
COPY --chown=coder:coder settings.json ${CODE_USER}/

# Install Node.js LTS using NVM
RUN curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh" | bash \
    && export NVM_DIR="$HOME/.nvm" \
    && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" \
    && nvm install --lts --latest-npm

# Install extensions (meaningless when bind directory)
#RUN code-server --install-extension ms-ceintl.vscode-language-pack-ko
#RUN code-server --install-extension pkief.material-icon-theme
#RUN code-server --install-extension ms-dotnettools.csharp
#RUN code-server --install-extension ms-python.python
#RUN code-server --install-extension ms-vscode.typescript-javascript-grammar
#RUN code-server --install-extension christian-kohler.npm-intellisense
#RUN code-server --install-extension eamodio.gitlens

# APT & /tmp cleanup
RUN sudo apt-get clean -y && sudo rm -rf /var/lib/apt/lists/*
RUN sudo rm -rf /tmp/*

# FINAL
RUN sudo chown -R coder:coder /home/coder

EXPOSE 8080

ENTRYPOINT ["/usr/bin/entrypoint.sh",        \
                "/home/coder/projects",      \
                "--bind-addr=0.0.0.0:8080",  \
                "--disable-telemetry",       \
                "--user-data-dir={0}",       \
                "--extensions-dir={1}"]
# {0] will be replaced to $CODE_DATA, {1} will be replaced to $CODE_EXTENSIONS in entrypoint.sh

### BIND
# (required) [host project folder] -> /home/coder/projects
# (recommended) [host vscode conf folder] -> /home/coder/.local/share/code-server
