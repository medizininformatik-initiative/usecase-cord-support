# Base image https://hub.docker.com/u/rocker/
FROM rocker/r-base:latest

# LABEL
LABEL envs="[{\"name\":\"FHIR_API\",\"type\":\"string\",\"required\":true}]"

WORKDIR /home

## install debian packages
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
libxml2-dev \
libcairo2-dev \
libsqlite3-dev \
libmariadbd-dev \
libpq-dev \
libssh2-1-dev \
unixodbc-dev \
libcurl4-openssl-dev \
libssl-dev

## copy files
COPY  . .

## run the script
RUN Rscript install_packages.R

## run the script
CMD Rscript fhir2csv.R