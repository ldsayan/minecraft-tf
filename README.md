# Minecraft Deployment with Terraform

## Background

WHAT, HOW

## A. Requirements

### A1. Pre-installed software

The following must be pre-installed and available on your system's `PATH`:
1. The `aws` CLI. [Follow the instructions by AWS here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. Terraform. [Follow the instructions by Terraform here](https://developer.hashicorp.com/terraform/install)
3. It is recommended that you install `git` to clone this repository. You can however choose to download a ZIP from GitHub.

### A2. AWS Account

You must have an AWS account where you have access to the [`ECS Infrastructure Role`](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/infrastructure_IAM_role.html). If you're using AWS Academy, then you should be able to use the provided `LabRole` Once you have a functioning account please set the credentials using the `~/.aws/credentials` file (or `C:\Users\<USERNAME>\.aws\credentials` if on Windows).

```toml
[default]
aws_access_key_id=<access_key>
aws_secret_access_key=<secret_key>
aws_session_token=<session_token_if_applicable>
```

> NOTE: You may not need to set up `aws_session_token` if you're not using a AWS Academy account.

### A3. Environment Variables

Make sure the following environment variables are set:

```sh
export AWS_DEFAULT_REGION=us-east-1
```

> NOTE: Replace with your region as is appropriate


## B. Diagram

Major steps.

## C. Instructions

```sh
# clone the repository (if cloning)
git clone https://github.com/ldsayan/minecraft-tf.git
# init
terraform init
# verify the terraform plan
terraform validate
# if all ok, run below. NOTE: you may have to interactively input "yes" to deploy
terraform apply
```

If all goes well, the script will output the public IP address of your minecraft instance which you can then connect to and invite others to play on.


## How to connect

1. Simply start the Minecraft launcher on your local machine
2. Click on play
3. Click on multiplayer
3. Click on add server
4. Enter the IP address that was shown as output earlier
5. You're ready to play

## License

This code is distributed under the [MIT License](./LICENSE).
