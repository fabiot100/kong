# Kong + ModSecurity installation tutorial using Docker

This tutorial explains how to install Kong with ModSecurity using Docker.

[Kong](https://github.com/Kong/kong) </br>
[ModSecurity](https://github.com/SpiderLabs/ModSecurity)

- [Kong + ModSecurity installation tutorial using Docker](#kong--modsecurity-installation-tutorial-using-docker)
  - [Explaining some files/folders](#explaining-some-filesfolders)
  - [Step 1 - Kong certificates (Virtual servers)](#step-1---kong-certificates-(virtual-servers))
  - [Step 2 - Preparing database](#step-2---preparing-database)
    - [Creating certificates](#creating-certificates)
      - [Configuring certificates on client](#configuring-certificates-on-client)
    - [Configuring PostgreSQL](#configuring-postgresql)
  - [Step 3 - Environments variables](#step-3---environments-variables)
  - [Step 4 - docker-compose.yml](#step-4---docker-composeyml)
  - [Step 5 - Kong logs](#step-5---kong-logs)
  - [Step 6 - Initializing ModSecurity](#step-6---initializing-modsecurity)
  - [Step 7 - Security policies](#step-7---security-policies)
  - [Step 8 - Results](#step-8---results)

**NOTE** - Our workdir will be ***/opt/devops/kong***.

**NOTE - This Kong version is 3.5.0 (open source).**

## Explaining some files/folders

**kong/etc/kong/certif/** - this folder is where you put the certificates (database and others). This folder is used only if your project uses certificate(s);

**build/plugins** – this folder is where you put the custom plugins;

**kong/etc/kong/my-server.kong.konf** – this is the custom openresty configuration file for this project, including certificates, configs and others.

## Step 1 - Kong certificates (Virtual servers)

To configure Kong certificates (Virtual servers), save them in **./kong/etc/kong/certif** folder and configure them at **kong/etc/kong/my-server.kong.conf**.

**NOTE** - For update/new certificate, you'll have to restart kong container after that to apply the new certificate.

## Step 2 - Preparing database

To keep secure our connection between application and database, you'll configure an auto assign certificate for comunication **(I don't recommend to use auto assign certificate for production purpose)**. This certificate will be a **100 years valid**.

**NOTE 1** - You'll need to start for the first time your PostgreSQL and create the application database. So execute the following command: 'docker-compose up -d kong.db.com.br'

### Creating certificates

To create server and client certificates, folow the steps at the file "how_to_create_postgresql_certificate.sh". There it explains how to create, step by step.

Remember: you must to be at PostgreSQL path (/opt/devops/kong/postgresql/kong-db, for example).

#### Configuring certificates on client

After creating the certificates, you have to create a bundle.pem using the client.crt, client.key and root.crt. By default, I used client_bundle.pem as the bundle name. This bundle will be used at [Step 2](#step-2-preparing-database-(sandbox-only)) at KONG_LUA_SSL_TRUSTED_CERTIFICATE variable. Once certificate created, copy it into ./certif folder.

### Configuring PostgreSQL

Certificates created, now you have to configure de PostgreSQL configs files: *pg_hba.conf* and *postgresql.conf*

*pg_hba.conf* - at botton of the file, configure like the following:

```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust

hostssl kong kong 192.168.50.11/32 scram-sha-256 clientcert=0  #conexão Kong
hostssl all all 0.0.0.0/0 cert  clientcert=1
```

The three last lines are what really matter now. The penult line is about the connection using certificate, allowing only the listed container source (kong). The last one line means that it's necessary a certificate configured on client to make the connection (in this case, all sources are liberated).

**NOTE** - Open source Kong version doesn't accept clientcert option equal to 1. So knowing this, I'm using both methods (user/password and certificate).

*postgresql.conf* - in this file you'll configure the certificates path. Search in this file for the following lines:

```conf
# - SSL -

ssl = on
ssl_ca_file = './certs/root.crt'
ssl_cert_file = './certs/server.crt'
#ssl_crl_file = 'server.key'
ssl_key_file = './certs/server.key'
ssl_ciphers = 'HIGH:!ADH:!SHA1:!3DES:!RC4'
```
## Step 3 - Environments variables

Open /env/kong.env and adjust the parameters. At Konga environment, it's commented the LDAP configuration, but if you want to use it, junt uncomment and set the right values.

```
#postgres
POSTGRES_USER=                                      # database_username
POSTGRES_PASSWORD=                                  # database_password
POSTGRES_DB=                                        # database_name
POSTGRES_INITDB_ARGS=--auth-host=scram-sha-256      # database_encryptation

#kong environment
KONG_DATABASE=                                  # database_adapter
KONG_PG_HOST=                                   # database_host
KONG_PG_USER=                                   # database_username
KONG_PG_PASSWORD=                               # database_password
KONG_PG_DATABASE=                               # database_name
KONG_PG_PORT=                                   # database_port
KONG_PROXY_ACCESS_LOG=/dev/stdout
KONG_ADMIN_ACCESS_LOG=/dev/stdout
KONG_PROXY_ERROR_LOG=/dev/stderr
KONG_ADMIN_ERROR_LOG=/dev/stderr
KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl
KONG_PROXY_LISTEN=0.0.0.0:8000, 0.0.0.0:8443 ssl
KONG_ADMIN_GUI_URL=http://localhost:8002
KONG_PLUGINS=bundled, session                                                   # custom_plugins_load
KONG_LOG_LEVEL=info
KONG_NGINX_HTTP_INCLUDE=/etc/kong/my-server.kong.conf                           # custom_nginx_config_path
KONG_PG_SSL=on                                                                  # database_certificate_on/off
KONG_PG_SSL_VERIFY=on                                                           # database_certificate_verify_on/off
KONG_LUA_SSL_TRUSTED_CERTIFICATE=/etc/kong/certif/client_bundle.pem             # database_bundle_certificate_path

```
## Step 4 - docker-compose.yml

**NOTE 1** - If you already have a populated database (using an older kong version, for example), skip this step and go to [step 5](#step-5-kong-logs).

1. Adjustments did, now you need to verify the docker-compose.yml file and do some configs. The code below contains only a part of the file with the lines you'll have to change. The commands should be uncommented and commented sometimes, but don’t worry, I’m going to explain soon:

```yml
kong:  
  build: ./build
  container_name: kong
  depends_on:
    - kong.db.com.br
#  command: "kong migrations bootstrap"
#  command: "kong migrations up" 
#  command: "kong migrations finish"
    ...
    ...
    ...
```

In the first time the project is started with “docker-compose up -d”, the database is created but with no data. Then, follow these steps:

• uncomment the first command (kong migrations bootstrap);

• run the “docker-compose up -d” command;

• comment the first command;

• run the “docker-compose up -d” command again;

**NOTE 2**: If you are only upgrading your Kong, you'll need to use "kong migrations up" and "kong migrations finish" instead, using teh same logic explained above.

**kong migrations bootstrap** - used to initiate a empty database;

**kong migrations up** - used to adapt the existing database with a upgrade;

**kong migrations finish** - used to end the procces of migration.

## Step 5 - Kong logs

Take a look at the Kong logs on Docker. Sometimes somethings goes wrong and doesn't work propertly. If you see, for example, something like "need migrations", you'll need to execute part of the step above (migrations up and finish, respectively). Follow the steps below to see the logs:

```bash
# Step 1
docker ps -a

# Step 2
docker logs container_name
```

## Step 6 - Initializing ModSecurity

Now you have to copy ModSecurity and coreruleset folders to your machine to work like a volume (if you don't copy them and only configure your docker-compose.yml, it will not work).

```bash
# First:
cd /opt/devops/kong/kong && \
    docker cp kong:/ModSecurity .

# Second:
cd /opt/devops/kong/kong && \
    mkdir usr/ && cd usr/ && \
    mkdir local/ && cd local/ && \
    docker cp kong:/usr/local/coreruleset .
```

After that, uncomment the two volume lines at *docker-compose.yml*:

```yml
    ...
    ...
    volumes:
      - "./kong/var/log/kong:/var/log/kong:z"
      - "./kong/etc/kong:/etc/kong:z"
#      - "./kong/ModSecurity:/ModSecurity"
#      - "./kong/usr/local/coreruleset:/usr/local/coreruleset"
    ...
    ...
```

At last, to activate ModSecurity, uncomment the two config lines at *kong/etc/kong/my-server.kong.conf*:

```conf
# modsecurity on;
# modsecurity_rules_file /usr/local/modsec_includes.conf;
```

Now, execute the command below to restart all the service:

```bash
docker-compose down && docker-compose up -d
```

## Step 7 - Security policies

To ensure the folders and files security, you should now apply some security policies:

```bash
cd /opt && chmod 775 devops/ && \
cd devops && chmod 775 kong/ && \
cd kong && chmod 775 -R build/ env/ docker-compose.yml kong/
```

This will ensure that only root user (or users into root group) can edit files at Kong directory.

## Step 8 - Results

At this point, all the applications are running. To manage the kong, you can access the following link http://ip_machine:8002 and use Kong-Manager-OSS.