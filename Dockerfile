# ---- Build Stage ----
FROM elixir:1.13.4-otp-25-alpine as app_builder

# Set environment variables for building the application
ENV MIX_ENV=prod \
    TEST=1 \
    LANG=C.UTF-8

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install dependencies required to compile deps
RUN apk update && \
    apk add build-base

# Create the application build directory
RUN mkdir /app
WORKDIR /app

# Copy over all the necessary application files and directories
COPY apps ./apps
COPY config ./config
COPY mix.exs .
COPY mix.lock .

# Fetch the application dependencies and build the application
RUN mix deps.get
RUN mix deps.compile
RUN mix release

# ---- Application Stage ----
FROM alpine:3.16 AS app

ENV LANG=C.UTF-8

# Install openssl
RUN apk update && \
    apk add openssl ncurses-libs libstdc++ libgcc

# Copy over the build artifact from the previous step and create a non root user
RUN adduser -D app
WORKDIR /home/app
COPY --from=app_builder /app/_build .
RUN chown -R app: ./prod

# Copy the start script
ADD scripts/start_commands.sh /scripts/start_commands.sh
RUN chown app: /scripts/start_commands.sh && \
    chmod +x /scripts/start_commands.sh

USER app

# run the start-up script which run migrations and then the app
ENTRYPOINT ["/scripts/start_commands.sh"]
