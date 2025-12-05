FROM node:20 as builder

LABEL version="1.0.0"
LABEL description="Consumet API (fastify) Docker Image"

# update packages, to reduce risk of vulnerabilities
RUN apt-get update && apt-get upgrade -y && apt-get autoclean -y && apt-get autoremove -y

# set a non privileged user to use when running this image
RUN groupadd -r nodejs && useradd -g nodejs -s /bin/bash -d /home/nodejs -m nodejs
USER nodejs
# set right (secure) folder permissions
RUN mkdir -p /home/nodejs/app/node_modules && chown -R nodejs:nodejs /home/nodejs/app

WORKDIR /home/nodejs/app

# set default node env and port
ARG NODE_ENV=PROD
ARG PORT=3000
ARG REDIS_HOST
ARG REDIS_PORT
ARG REDIS_PASSWORD

# set environment variables with defaults
ENV NODE_ENV=${NODE_ENV}
ENV PORT=${PORT:-3000}
ENV REDIS_HOST=${REDIS_HOST}
ENV REDIS_PORT=${REDIS_PORT}
ENV REDIS_PASSWORD=${REDIS_PASSWORD}

ENV NPM_CONFIG_LOGLEVEL=warn

# copy project definition/dependencies files, for better reuse of layers
COPY --chown=nodejs:nodejs package*.json ./

# install dependencies here, for better reuse of layers
RUN npm install && npm update && npm cache clean --force

# copy all sources in the container (exclusions in .dockerignore file)
COPY --chown=nodejs:nodejs . .

# build/pack binaries from sources

# This results in a single layer image
# FROM node:lts-alpine AS release
# COPY --from=builder /dist /dist

# exposed port/s
EXPOSE 3000

# healthcheck - adjust the endpoint based on your API
# Use /health if your API has a health endpoint, otherwise use /
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s \
CMD curl --fail http://localhost:$PORT/ || exit 1

# start the application
CMD [ "npm", "start" ]

# end.