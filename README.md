# Symmetry Platform

![Deploy to Amazon ECS - Staging](https://github.com/Symmetry-Group/platform/workflows/Deploy%20to%20Amazon%20ECS%20-%20Staging/badge.svg)
![Deploy to Amazon ECS - Production](https://github.com/Symmetry-Group/platform/workflows/Deploy%20to%20Amazon%20ECS%20-%20Production/badge.svg)

## This repository
This is the new Symmetry Platform repository, it includes the learning and all the privacy related modules. 

In mid May 2020 Brevity uploaded to the [brevity repository](https://github.com/Symmetry-Group/brevity) the current (then) project as it was in production, on their old infrastructure. That snapshot was cloned into this repository (platform) and will be from now on the source of truth of the codebase.

This repository will be receiving all the required changes to run in the new AWS infrastructure being developed by [@conzy](https://github.com/conzy), plus all the security and code architecture improvements that are very much needed.

As Brevity continues to deliver the last few modules of the platform, they'll be imported into this repository to be then deployed to the new infrastructure.

## Contributing to this repository
Once you've cloned the repository, you can create a new branch prefixed with your username, for example:
```
git checkout -b username/my-branch
```
Apply any change you need, commit them, and push to origin using:
```
git push origin username/my-branch
```
The only step left is to go to the [platform repository on github.com](https://github.com/Symmetry-Group/platform) and open a Pull Request describing the changes you've done.

Soon we'll have proper automated testing and a build pipeline in place that will let us merge things with more confidence, but until then, it'll be great if you can get another of the Symmetry developers to review your changes before merging the PR.

## Additional Documentation

We have a [docs](./docs) directory with additional documentation that is related to the Symmetry Platform but not necessarily directly
related to running / contributing to the platform codebase. 

### Branch Protection

You can not push to the master branch on this repo. You must open a pull request and get at least one peer review (approval)

**It's important to always test your changes appropriately before releasing them to production**. We have contractual Service Levels Agreements with our customers that would make us refund their monthly payments if the platform doesn't meet the minimum criteria. If the platform suffered an outage longer than 36 hours on any given month, Symmetry will literally make no money that month - so we need to be super careful to not create outages caused by human errors.

## Running the project locally
This project runs on Docker. This is so our local development environment is pretty much identical to the staging and production stages. 

If you are on the windows platform you may find [this issue](https://github.com/Symmetry-Group/issues/issues/141) helpful

### Initial Steps
Install Docker. The Docker installation will differ depending on your operating system.

Once you've set it up, you can build the Platform images using:
```
docker-compose up
```
This will build a webserver, a database server, and the Laravel application itself - and once finished, you should be able to see on your browser by accessing [http://localhost](http://localhost), although most likely you'll just see an error, as there is no database yet, no env file and no packages installed by composer yet!

That URL is not very nice, so you should edit the hosts file on your computer to point the host `demo.symmetry.local` to your `localhost` or `127.0.0.1`. How to do that will depend on your operating system, but we can help you.

Once you've done that, visiting [http://demo.symmetry.local](http://demo.symmetry.local) should display the same error page. You'll be able to see the application working once to do the next step: importing the database.

## Importing the databases structure and the data
At the moment this operation is rather precarious. Unfortunately Brevity didn't consistently use migrations, so at the moment our only option until we decipher the structure of the databases, which ones are required, etc. we'll need to make it work this way:

Ask Conor for the dump of the databases and put them on the `database/dumps` directory, there are 3 dumps, and we are still figuring out the logic behind this:

* `symmetryplatform.sql` contains all the "system" tables. They are the tables used to keep track of customers accounts, billing, etc.
* `symmetrydefault.sql` is the database and data for the Symmetry account. (Not currently needed)
* `dump.sql` is a dump of all databases. 

The easiest way at the moment to get things working is to log into your database instance using Docker like this:
```
docker ps
# This will list your 3 Docker containers
# Copy the id (first column on the left) of the one called symmetrydb
# Replace DB_CONTAINER_ID with that ID
docker exec -it DB_CONTAINER_ID /bin/bash
```

You are now inside your container, and will be able to use the mysql client to import data, or access the prompt to access any database you may need. The password for root is in the mysql section of the docker-compose.

You can now import some of those dumps, to make your environment work. Usually importing the dump for the `symmetryplatform` database and the `demo` instance should work, like

```
mysql -u root -p < /tmp/dumps/demo.sql
mysql -u root -p < /tmp/dumps/symmetryplatform.sql
```
You can update the `demo.sql` to update some credentials, or anything you may need.

The password is the password set in docker-compose `mypassword`

Soon enough we want to improve this: create smaller and neater files containing the schema of the databases we need, create as well test data, and leave anything else out, as it's a big no-no to have real data in our development systems.

### phpMyAdmin

We have integrated phpMyAdmin with the local development environment. It will run on port 8080 so you can get to it at:

[http://127.0.0.1:8080/index.php](http://127.0.0.1:8080/index.php)

Login with the details in docker-compose.yml

You can also connect to the DB on 127.0.0.1 on port 3306 with the MySQL client of your choice

## Env

You need to make a copy of the `.env.example` file. 

`cp .env.example .env`

The `.env` file is gitignored so it wont make it into version control. We run the app locally using Docker. Our `docker-compose.yml` defines
a volume `./:/var/www` this mounts the root of this repo into the `/var/www` directory in container. This means the .env file is also available in the
container.

## Composer

You _could_ install composer locally and run `composer install` in the root of this repo. However its more convenient to run `composer install` in our PHP container.

Note: Keep in mind the `vendor` directory in this repo is mounted in the container. So running composer inside or outside of the container is the same thing.

The steps are very similar to the database import above. We need to exec into the php container. To do that we run `docker-compose ps` you can see the names of the containers running as part of this "docker-compose"

```text
docker-compose ps
   Name                 Command              State           Ports
---------------------------------------------------------------------------
symmetry     docker-php-entrypoint php-fpm   Up      9000/tcp
symmetrydb   docker-entrypoint.sh mysqld     Up      0.0.0.0:3306->3306/tcp
symmetryws   nginx -g daemon off;            Up      0.0.0.0:80->80/tcp
```

Our php container is called `symmetry` so to get a shell on that container we can run `docker exec -it symmetry /bin/bash`

You will now be the `www` user in the `/var/www` directory. You can run `composer install` to install the required packages.

You can then run `php artisan key:generate` to generate the secret key for the application. You can see that the `APP_KEY` key
in the `.env` file now has a value.

## Login

At this point if you have created the following entry in your hosts file:

```
127.0.0.1       localhost demo.symmetry.local
```

You should be able to log in with the following details:

```
User: demo@symmetrygdpr.com
Pass: 12345
```

## App Infrastructure

The following section is related to running the app in an AWS environment. We use AWS ECS (Fargate) as the container
orchestrator. The app is deployed to isolated AWS accounts. More info on the infra is available in our infrastrucre / terraform
[repo]()

## Deployment

Right now this repo is configured to deploy to the staging environment when we merge to the master branch. Creating
a [release](https://github.com/Symmetry-Group/platform/releases) will deploy to the production account

We use GitHub Actions for CI/CD. We use the AWS GitHub Actions to:

- Configiure credentials and assume role in appropriate AWS account
- Login and push images to ECR
- Render and register latest task definition
- Wait for service stability

There is a github_actions AWS IAM *User* in the master account. These credentials are stored as a [GitHub Secret](https://github.com/Symmetry-Group/platform/settings/secrets) 

### Trigger a deployment

As mentioned deployments are triggered automatically when PRs are merged or releases are created. Sometimes you may want to
trigger a deployment manually to test the pipeline or because GitHub Actions did not run on your PR. This is rare but can
happen if GitHub are having issue or their webhooks fail to trigger the build. If you notice this happening you can simply
create a PR with an empty commit like this:

`git commit --allow-empty`

Once you merge that PR it will trigger a build. 

Alternatively just update the README or any file in the repo and create / merge the PR.

## AWS

Your AWS login is for an account we refer to as `master` as it is the Organization master. We have child accounts such
as:

- sandbox (mainly used for infra / terraform development and feature branches)
- staging (Entire staging platform resides here, merge to master deploys here)
- production (Production platform resides here, tag / release deploys here soon)

You always log in to the master account. You then assume _roles_ in the other accounts.

### Staging

Login to master then click [here](https://signin.aws.amazon.com/switchrole?roleName=poweruser&account=symmetry-staging)

Poweruser role has many permissions but infra changes should only be made via terraform.

### Production
Login to master then click [here](https://signin.aws.amazon.com/switchrole?roleName=readonly&account=symmetry-production)

Production is read only for now. All infra changes are via terraform

### Master (S3 development bucket)
Login to master than click [here](https://signin.aws.amazon.com/switchrole?roleName=development&account=symmetry-master)

This role only has access to the S3 development bucket. You should assume this role when you need to interact with the
[eu-west-1-761740929414-storage-development](https://s3.console.aws.amazon.com/s3/buckets/eu-west-1-761740929414-storage-development/) bucket.

Because the application writes files to S3 we have to have an 
S3 bucket _somewhere_ the most sensible place to create this was in master. There is an extremely limited IAM user
which has access to this bucket. The credentials for that user are used in the docker-compose.yml to make interacting
with S3 in development trivial.

### Logs

Regardless of the account logs for the privacy platform should be available [here](https://eu-west-1.console.aws.amazon.com/ecs/home?region=eu-west-1#/clusters/privacy/services/privacy/logs)
in the ECS logs service. This just surfaced the Cloudwatch Logs log stream. You can also view the logs in Cloudwatch
directly.

## Utils

The application runs in a containerised environment so we provide a "Utils" EC2 instance. Access to this machine is
via AWS Systems Manager Session Manager and session logs are persisted to AWS Cloudwatch. This machine can be used for
carrying out maintenance on the DB etc.

The original developers of the app (Brevity) had very poor hygiene when it comes to migrations and processess in general.. 
There are only a handful of migrations and no process for running them as of yet.

In the future migrations should be applied automatically. They could be run as a simple ECS RunTask on the `privacy`
cluster. They would have the same security group etc as the application so would be able to interact with the database.

At present this is a vanilla Amazon Linux 2 machine and uses the stock AMI

We have installed MySQL client as follows:

```bash
sudo yum install -y https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
sudo yum install -y mysql-community-client
```

### Utils Bucket

We also create a Utils S3 bucket. This can be convenient for copying files to/from the utils instance.

## MySQL

We create a MySQL user with reasonably limited privileges for running the app:

```sql
GRANT CREATE TEMPORARY TABLES, DELETE, EXECUTE, INSERT, LOCK TABLES, SELECT, UPDATE ON *.* TO 'privacy'@'%' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
```

We also create a user with more privileges that is used for running migrations:

```sql
GRANT ALTER, CREATE, CREATE TEMPORARY TABLES, DELETE, DROP, INDEX, INSERT, LOCK TABLES, REFERENCES, SELECT, UPDATE ON *.* TO 'migrations'@'%' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
```

*Note:* As this `privacy` user has limited permissions we may need to create another user that has the ability to
generate new accounts or "instances"

## Secrets

If you look at the task-definition you can see we pass many secrets to the running container. These are created in 
[parameter store](https://eu-west-1.console.aws.amazon.com/systems-manager/parameters?region=eu-west-1)

String such as app_url can be stored as the `String` data type. But secrets such as app_key and db_password should be stored
as `SecureString`

### Required Parameters

Here is the bare minimum list of parameters that the app needs when running in ECS

- /app/privacy/app_key (SecureString)
- /app/privacy/app_url (String)
- /app/privacy/db_host (String)
- /app/privacy/db_password (SecureString)
- /app/privacy/db_username (String)

## Feature Branch Deployment

Feature branches are deployed to the Sandbox account. You can use the `admin` role in the `symmetry-sandbox` account.
You can click [here](https://signin.aws.amazon.com/switchrole?roleName=admin&account=symmetry-sandbox) to swap to that role.

### How it works

Right now its a straightforward approach. If your branch name begins with `dev/` it will automatically be deployed
to the sandbox account. This means you can name a branch `dev/my-cool-test` or rename an existing local branch
using `git branch -m dev/my-cool-branch` and it will trigger the [workflow](platform/.github/workflows/aws_sandbox.yml)

You can see the trigger:

```yaml
on:
  push:
    branches:
      - dev/**
```

If you wanted to modify this or add additional triggers.

There is only _1_ service available in the account. i.e there is just one more environment and the latest push
to each branch matching the pattern will be deployed. For this reason its worth talking to teammates
to "claim" the environment if you need to test something.

There would be a good bit more complexity and cost involved in supporting an arbitrary number of environments

#### Monitoring and Logs

You can see logs in the [ECS Console](https://eu-west-1.console.aws.amazon.com/ecs/v2/clusters/privacy/services/privacy/logs?region=eu-west-1) you
can also check Cloudwatch directly. You should monitor the progress of your deployment in GitHub Actions

The [task definition](https://eu-west-1.console.aws.amazon.com/ecs/v2/task-definitions/privacy/40/containers?region=eu-west-1) defines the task
such as what image it uses. You can view the task definition to see what container image is deployed.

#### DB Changes and Maintenance

For the sandbox environment there is also the [utils](#utils) EC2 box in that account, you can connect to this
using Systems Manager Session Manager. The password for the `root` user is in Parameter Store [here](https://eu-west-1.console.aws.amazon.com/systems-manager/parameters/root_db_password/description?region=eu-west-1&tab=Table)
or you can get it in 1password [here](https://start.1password.com/open/i?a=TMMNDMFJCRFVLKHJPBLZ7YMA34&v=4b4gz2vokblatjsnryejmdn3re&i=uds7lwikzndr3e3kik2hpwi6i4&h=symmetrygroup.1password.com)

Note: You should never put production dumps into this database, you can create manual databases / tables or import
safe data from staging etc.
