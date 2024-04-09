FROM hashicorp/terraform

RUN apk add aws-cli

RUN git config --global --add safe.directory /workspace

ENTRYPOINT /bin/sh
