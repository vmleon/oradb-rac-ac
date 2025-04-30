#!/usr/bin/env zx
import Mustache from "mustache";
import Configstore from "configstore";
import clear from "clear";

$.verbose = false;

clear();
console.log("Create Terraform tfvars file...");

const projectName = "dbrac";

const config = new Configstore(projectName, { projectName });

const profile = config.get("profile");
const tenancyId = config.get("tenancyId");
const regionName = config.get("regionName");
const compartmentId = config.get("compartmentId");
const publicKeyContent = config.get("publicKeyContent");
const sshPrivateKeyPath = config.get("privateKeyPath");
const certFullchain = config.get("certFullchain");
const certPrivateKey = config.get("certPrivateKey");
const compartmentName = config.get("compartmentName");

await generateTFVars();

async function generateTFVars() {
  const tfVarsPath = "tf/terraform.tfvars";

  const tfvarsTemplate = await fs.readFile(`${tfVarsPath}.mustache`, "utf-8");

  const output = Mustache.render(tfvarsTemplate, {
    region_name: regionName,
    config_file_profile: profile,
    tenancy_id: tenancyId,
    compartment_id: compartmentId,
    cert_fullchain: certFullchain,
    cert_private_key: certPrivateKey,
    ssh_public_key: publicKeyContent,
    ssh_private_key_path: sshPrivateKeyPath,
  });

  console.log(
    `Terraform will deploy resources in ${chalk.green(
      regionName
    )} in compartment ${
      compartmentName ? chalk.green(compartmentName) : chalk.green("root")
    }`
  );

  await fs.writeFile(tfVarsPath, output);

  console.log(`File ${chalk.green(tfVarsPath)} created`);

  console.log(`1. ${chalk.yellow("cd tf")}`);
  console.log(`2. ${chalk.yellow("terraform init")}`);
  console.log(`3. ${chalk.yellow("terraform apply -auto-approve")}`);
}
