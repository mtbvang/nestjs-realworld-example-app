########################################################################################################################
# Development stage/s. This is used in our docker-compose setup to develop locally.
########################################################################################################################

FROM node:12.14.1 as api-dev

RUN apt-get update -qq > /dev/null && \
  apt-get install curl sudo wget -qq > /dev/null
RUN wget --no-check-certificate --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch"-pgdg main | tee  /etc/apt/sources.list.d/pgdg.list
RUN apt-get update -qq > /dev/null && \
  apt-get install postgresql-client-11 -qq > /dev/null

ENV TZ Europe/Copenhagen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

WORKDIR /app
COPY package.json /app
RUN npm install --silent
#RUN npm install

# App port
EXPOSE 3000


########################################################################################################################
# Production stages. We install our prod dependencies in the testing image and them copy them over for production.
# The testing and production stages document the difference in resources required for the two different
# setups.
########################################################################################################################

# ----------------------------------------------------------------------------------------------------------------------
# BAse layer shared by test and prod
# ----------------------------------------------------------------------------------------------------------------------
FROM node:alpine as api-base
RUN apk add --no-cache postgresql-client bash tini openssl make gcc g++ python npm git py-pip curl musl-dev python-dev \
    libffi-dev openssl-dev \
    build-base

# Install AWS tools
# RUN pip install aws-encryption-sdk-cli==1.8.0

WORKDIR /app

ENTRYPOINT ["/sbin/tini", "--"]
# Uncomment and replace commands to keep container running for debugging
#CMD tail -f /dev/null
# Run script for AWS
#CMD ["/app/bin/run-app.sh"]

# ----------------------------------------------------------------------------------------------------------------------
# Testing layer used to run tests in container for CI.
# ----------------------------------------------------------------------------------------------------------------------
FROM node:alpine as api-test

USER node
COPY package.json package-lock.json /app/
RUN npm i --silent

COPY . /app/
RUN npm run build


# ----------------------------------------------------------------------------------------------------------------------
# Production layer used to run tests in container for CI.
# ----------------------------------------------------------------------------------------------------------------------
FROM api-test as api-prod

RUN npm install --prod

# Only copy exactly what we need to run on dev, stage and prod. There is no make and npm.
COPY --from=api-test /app/dist /app/dist

# CMD [ "npm", "start" ]
CMD ["node", "dist/main.js"]
EXPOSE 3000


