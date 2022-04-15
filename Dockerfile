FROM elixir:1.12-alpine
RUN apk add --update --no-cache alpine-sdk nodejs npm docker-cli sudo
COPY . /app
WORKDIR /app
RUN mkdir /app/workdir
RUN addgroup -S phoenix
RUN addgroup -S docker
RUN adduser -S phoenix -G phoenix
RUN addgroup phoenix docker
RUN chown root:docker /usr/bin/docker
RUN chmod u+s,o-rx /usr/bin/docker
RUN chown -R phoenix:phoenix .
USER phoenix
RUN git config --global user.name "TPanel"
RUN git config --global user.email "tpanel@cm-ss13.com"
RUN MIX_ENV=prod mix local.hex --force
RUN MIX_ENV=prod mix local.rebar --force
RUN MIX_ENV=prod mix deps.get --only prod --force
RUN MIX_ENV=prod mix compile
RUN MIX_ENV=prod mix assets.deploy
RUN chmod a+rx /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
