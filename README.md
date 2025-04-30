# Oracle Database RAC and AC

Oracle Database with Real Application Cluster (RAC) and Application Continuity (AC).

![Architecture Diagram](images/architecture.drawio.png)

## Deploy

### Clone Repository

Go to OCI Cloud Shell and clone the repository.

```bash
https://github.com/vmleon/oradb-rac-ac.git
```

Go to the new folder `oradb-rac-ac`

```bash
cd oradb-rac-ac
```

### Setup environment

Install the dependencies for the scripts in [Google ZX](https://google.github.io/zx/).

```bash
cd scripts/ && npm install && cd ..
```

### Build components

Build website

```bash
cd src/web
```

```bash
npm install
```

```bash
npm run build
```

```bash
cd ../..
```

Build Backend

```bash
cd src/backend
```

```bash
./gradlew clean bootJar
```

```bash
cd ../..
```

Answer all the questions from `setenv.mjs` script:

```bash
zx scripts/setenv.mjs
```

### Deploy with Terraform

Generate the `terraform.tfvars` file:

```bash
zx scripts/tfvars.mjs
```

Run the commands that `tfvars.mjs` output in yellow one by one.

> Alternative: One liner for the yellow commands (for easy copy paste)
>
> ```bash
> cd tf && terraform init && terraform apply -auto-approve
> ```

Come back to the root folder:

```bash
cd ..
```

### Connect to Database

Create the bastion host session

```bash
zx scripts/bastion-session.mjs
```

Paste the yellow command to connect with SSH into the compute instance.

To connect, asnwer `yes` to add the fingerprint to the know hosts.

Run a simple SELECT command to check everything is working fine.

```bash
echo "select banner from v$version; exit;" | sql -name admin
```

To exit the SSH connection with the compute instance:

```bash
exit
```

### Clean up

Go to the folder `tf`.

```bash
cd tf
```

Run the Terraform destroy:

```bash
terraform destroy -auto-approve
```

Come back to the root compartment:

```bash
cd ..
```

Clean all auxiliary files:

```bash
zx scripts/clean.mjs
```
