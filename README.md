# Anacounts

<strong>Share expenses, make it fair</strong>

Anacounts is a free and open-source application meant to easen the burden of
sharing expenses. It allows to split the bill via different means, to make it
more fair.

## Hosting

The application is currently available at
[anacounts.herokuapp.com](https://anacounts.herokuapp.com/).

Be aware that the application is still unstable and data loss may occur.
It is currently hosted on Heroku free tier, which is going down by the end
of November. I will change the host by then.

## Deployment

When contributing to **this repository**, the changes are applied immediately
when merged to master. The app is on rolling release, which I find the most
simple way of handling release for now.

You should be able to roll **your own replica** fairly easily. The application
was made in order to be as easy to replicate as possible, and as configurable
as possible. It does not enforce you to use the same host as I do. You will most
likely need some changes in the config files though, so you should consider
forking the repository.

The whole infrastructure is handled via Terraform. I do not want to disclose
the config files for the time being, as I plan to change the platform is is
hosted on.

## Contributing

All contributions are welcome, whether code, reviews, testing or anything
really! The project is too young to have a code of conduct or contributing
guidelines. Just know that I can be pretty picky on reviews - you've been
warned 😄

### Getting started

**Tools**

The project runs on Elixir/Phoenix, and a little NodeJS for packaging.
You should consider installing the required tools through
[asdf](https://asdf-vm.com/). Once asdf is ready, run `asdf install` whilst in
the project, and let it install everything you need to run the project.

```sh
$ asdf install
```

**Dependencies**

Once the Elixir language, Erlang VM, and NodeJS are installed, you will need
to fetch the dependencies of the project. There are no NodeJS dependencies (so
long `node_modules`), so all you have to do is run `mix deps.get`. If you
haven't installed it already, this command will prompt you to install "Hex"
(and maybe "rebar3"), which you should do.

```sh
$ mix deps.get
```

The dependencies were fetched and will be compiled when starting the project
for the first time. That's almost it! The last thing we need is a database -
could become handy right?

**Database**

The app uses PostgreSQL as dbms. For local development, I personally favour
using a Docker container over actually installing PostgreSQL on my machine -
it's easier to get rid of.

Here is the minimal command you can use to create a Postgres container.

```sh
$ docker run \
    --name anacounts-postgres \
    --env POSTGRES_PASSWORD=postgres \
    --publish 5432:5432 \
    --detach \
    postgres
```

If you don't use Docker to create your database, know that all you need for dev
and test environments is a database hosted on localhost, which username and
password is "postgres". The database will automatically be created later by
Ecto - the library handling the database.

Once the database is up-and-running, we can actually create the Postgres
databases. To do that, run the command `mix ecto.setup` from the `apps/app`
directory. This will create an "anacounts_dev" database and run the migrations.

```sh
$ cd apps/app
$ mix ecto.setup
```

**Run the app**

The development environment is ready for Anacounts to start! Go back to the
root directory, and launch the application with `mix phx.server`. You can now
go to `http://localhost:4000` and find your version of Anacounts 🥳

Note that in dev mode, the emails are not actually sent, they are displayed in
an internal mailbox available at `/internal/mailbox`.
