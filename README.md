# ![Node/Express/Mongoose Example App](project-logo.png)

[![Build Status](https://travis-ci.org/anishkny/node-express-realworld-example-app.svg?branch=master)](https://travis-ci.org/anishkny/node-express-realworld-example-app)

> ### NestJS codebase containing real world examples (CRUD, auth, advanced patterns, etc) that adheres to the [RealWorld](https://github.com/gothinkster/realworld-example-apps) API spec.


----------

# Getting started



## Installation

Clone the repository

    git clone https://github.com/lujakob/nestjs-realworld-example-app.git

Switch to the repo folder

    cd nestjs-realworld-example-app
    
Start the database and api containers and test the api with `http://localhost:23000/api/articles` in your favourite browser

    make up db-restore-local logs
    
Start the api app on your local host and test the api with `http://localhost:3000/api/articles` in your favourite browser

   npm install
   make set-env-file-local
    
Stop the docker containers

    make stop
    
To show the makefile hel;

    make help
    
----------

## Database

The codebase contains examples of two different database abstractions, namely [TypeORM](http://typeorm.io/) and [Prisma](https://www.prisma.io/). 
    
The branch `master` implements TypeORM with a postgres database.

The branch `prisma` implements Prisma with a postgres database.


----------

##### TypeORM

----------

The postgres database with the name `nestjsrealworld`\
(or the name you specified in the .env.* dotenv TYPEORM_* variable)

Start local postgres server and create new database 'nestjsrealworld'

    make up-database db-restore-local

The database schema for local developmnt need to be created and test fixtures loaded after starting the database container. 
The corresponding makefile targets to do this are:

    make db-migration-run-local
    make db-load-fixtures-local
    
Generate database migrations

    make db-migration-generate
    
This will compare the your entity changes with the local database schema and generate a migration script in src/migrations
e.g. 1594235982458-v1_.ts. 

Run database migrations (locally)

    mak db-migration-run-local

----------

##### Prisma

----------

To run the example with Prisma checkout branch `prisma`, remove the node_modules and run `npm install`

Create a new postgres database with the name `nestjsrealworld-prisma` (or the name you specified in `prisma/.env`)

Copy prisma config example file for database settings

    cp prisma/.env.example prisma/.env

Set postgres database settings in prisma/.env

    DATABASE_URL="postgres://USER:PASSWORD@HOST:PORT/DATABASE"

To create all tables in the new database make the database migration from the prisma schema defined in prisma/schema.prisma

    npx prisma migrate save --experimental
    npx prisma migrate up --experimental

Now generate the prisma client from the migrated database with the following command

    npx prisma generate

The database tables are now set up and the prisma client is generated. For more information see the docs:

- https://www.prisma.io/docs/getting-started/setup-prisma/add-to-existing-project-typescript-postgres


----------

## NPM scripts

- `npm start` - Start application
- `npm run start:watch` - Start application in watch mode
- `npm run test` - run Jest test runner 
- `npm run build` - Build application
- `npm run start:prod` - Start the application from the built files
----------

## API Specification

This application adheres to the api specifications set by the [Thinkster](https://github.com/gothinkster) team. This helps mix and match any backend with any other frontend without conflicts.

> [Full API Spec](https://github.com/gothinkster/realworld/tree/master/api)

More information regarding the project can be found here https://github.com/gothinkster/realworld

----------

## Start application

- `npm start`
- Test api with `http://localhost:3000/api/articles` in your favourite browser

----------

# Authentication
 
This applications uses JSON Web Token (JWT) to handle authentication. The token is passed with each request using the `Authorization` header with `Token` scheme. The JWT authentication middleware handles the validation and authentication of the token. Please check the following sources to learn more about JWT.

----------
 
# Swagger API docs

This example repo uses the NestJS swagger module for API documentation. [NestJS Swagger](https://github.com/nestjs/swagger) - [www.swagger.io](https://swagger.io/)        
