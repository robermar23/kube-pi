FROM alpine:3.11.3
WORKDIR /home/weave
RUN apk add --no-cache bash conntrack-tools iproute2 util-linux curl
COPY ./scope /home/weave/

RUN apk add --no-cache runit
COPY ./demo.json /
COPY ./weave ./weaveutil /usr/bin/
COPY ./runsvinit ./entrypoint.sh /home/weave/
COPY ./run-app /etc/service/app/run
COPY ./run-probe /etc/service/probe/run
EXPOSE 4040
ENTRYPOINT ["/home/weave/entrypoint.sh"]

ARG revision
LABEL maintainer="Weaveworks <help@weave.works>" \
      org.opencontainers.image.title="scope" \
      org.opencontainers.image.source="https://github.com/weaveworks/scope" \
      org.opencontainers.image.revision="${revision}" \
      org.opencontainers.image.vendor="Weaveworks"