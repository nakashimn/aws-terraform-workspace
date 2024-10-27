FROM ubuntu:22.04

ARG PLURALITH_VERSION=0.2.1
ARG PLURALITH_API_KEY=""

# ENV PATH=${PATH}:/root/Pluralith/bin/
ENV PATH=${PATH}:/root/.tfenv/bin

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    awscli \
    curl \
    git \
    python3-pip \
    tzdata \
    unzip \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir aws-mfa

RUN curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
RUN dpkg -i session-manager-plugin.deb

RUN git clone https://github.com/tfutils/tfenv.git ~/.tfenv
RUN tfenv install 1.8.5
RUN tfenv use 1.8.5

# RUN wget https://github.com/Pluralith/pluralith-cli/releases/download/v${PLURALITH_VERSION}/pluralith_cli_linux_amd64_v${PLURALITH_VERSION} -O /usr/local/bin/pluralith \
#     && chmod +x /usr/local/bin/pluralith
# RUN pluralith login --api-key ${PLURALITH_API_KEY}
# RUN pluralith install graph-module
# RUN mkdir -p /root/Pluralith/bin \
#     && wget https://github.com/Pluralith/pluralith-cli-graphing-release/releases/download/v${PLURALITH_VERSION}/pluralith_cli_graphing_linux_amd64_${PLURALITH_VERSION} -O /root/Pluralith/bin/pluralith-cli-graphing \
#     && chmod +x /root/Pluralith/bin/pluralith-cli-graphing

RUN git config --global --add safe.directory /workspace
