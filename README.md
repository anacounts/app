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
really ! The project is too young to have a code of conduct or contributing
guidelines. Just know that I can be pretty picky on reviews - you've been
warned 😄
