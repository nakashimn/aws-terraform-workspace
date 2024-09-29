FROM hashicorp/terraform

RUN apk add aws-cli bash

RUN git config --global --add safe.directory /workspace

ENTRYPOINT /bin/sh
