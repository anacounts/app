# Deployment

Whilst I would have loved to have the complete infrastructure run on Terraform,
the Fly provider isn't mature enough to allow that. Actually, I chose not to
use it at all.

Hence, there are three parts to this deployment guide: one on Fly, another one
on Terraform - for the AWS part - and a last for the communication between the
two firsts.

Before getting started, make sure that both
[`flyctl`](https://fly.io/docs/hands-on/install-flyctl/) and
[`terraform`](https://www.terraform.io/downloads) are installed and working
properly.

## Create and configure a Fly app

Everything on Fly can be done using the `flyctl` command. The instructions will
be listed, with the corresponding command below each. All instructions can be
done through the web interface.

1. Create a Fly app.
```sh
fly apps create <app_name>
```

2. Create a PostgreSQL database
```sh
fly postgres create <db_name>
```

3. Attach the database to the application
```sh
fly postgres attach <db_name>
```

4. Add a certificate
```sh
fly certs add <app_hostname>
```

5. Add the IP v4 and v6 of the app and CNAME record to Terraform config.
Those can be found on the application dashbaord, on the page of the certificate
that was just created. You will need the "CNAME" record name and value, and the
A and AAAA records value. Put them in the corresponding variables in a newly
created `terraform.tfvars` file. The name of the variables can be found in
`variables.tf`. 

## Configure and launch Terraform

_TODO Write this part, I can't remember what to do here right now😓_

## Deploy the application

Before deploying the application for good, the secrets must be set. Use the
command `fly secrets set <secret_name> <secret_value>` to do that.
The secrets are environment variables used in `config/runtime.exs`, check them
out there. Note that `DATABASE_URL` was automatically set when attaching the
database.
