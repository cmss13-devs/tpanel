FROM elixir:1.12-alpine
RUN apk add --update alpine-sdk nodejs npm
COPY . /app
WORKDIR /app
RUN mkdir /app/workdir
RUN addgroup -S phoenix
RUN adduser -S phoenix -G phoenix
RUN chown -R phoenix:phoenix .
USER phoenix
RUN MIX_ENV=prod mix local.hex --force
RUN MIX_ENV=prod mix local.rebar --force
RUN MIX_ENV=prod mix deps.get --only prod --force
RUN MIX_ENV=prod mix compile
RUN MIX_ENV=prod mix assets.deploy
RUN chmod a+rx /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
