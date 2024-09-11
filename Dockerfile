ARG BUILDER_IMAGE="hexpm/elixir:1.14.5-erlang-25.0.4-debian-bullseye-20240904-slim"
ARG RUNNER_IMAGE="debian:bullseye-20240904-slim"

FROM ${BUILDER_IMAGE} AS builder

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

RUN echo $(ls)

COPY assets assets

RUN mix assets.deploy


RUN mix phx.digest

COPY priv priv

# Compile the release
COPY lib lib

RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/


RUN mix release


# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

ARG APP_NAME="test_fourteen"
ARG DATABASE_URL="ecto://postgres:password@jemputan-db/app_db"
ARG SECRET_KEY_BASE="IvIOwF3Wsrawamz1D5hILmDxpEMS6N4Nocoi+v/AlEaueKrR1KamYGqtuKjfwAzN"

ENV DATABASE_URL=$DATABASE_URL
ENV SECRET_KEY_BASE=$SECRET_KEY_BASE

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*


RUN groupadd --gid 1000 toor \
    && useradd --uid 1000 --gid 1000 toor

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV RELEASE_COOKIE mysecretcookie
ENV HOME=/app

WORKDIR /app

# Only copy the final release from the build stage
COPY --from=builder  /app/_build/prod/rel/$APP_NAME ./

RUN chown toor:toor -R /app

USER toor

CMD ["/app/bin/test_fourteen", "start"]

