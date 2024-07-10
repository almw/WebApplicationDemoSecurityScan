
##  Pipeline Docker Container Build and Security Scan
### Create Azure Container Registry
1. Login your Azure CLI, and set your subscription id
```bash
az cloud list --output table
az cloud set --name AzureCloud
az config set core.enable_broker_on_windows=true
az account clear
az login
az account set -s <your-subscription-id>
 ```
2. Create Azure Container Registry(ACR) & obtain ACR credentials and save them on file "azurecontainerregistryxxxx101.pw".
```bash
az acr create -n <your-registry-name> -g <your-resource-group-name> --sku <sku-name> --admin-enabled true
az acr credential show -n <your-registry-name>
```
### Prepare Jenkins server

1. Deploy a [Jenkins Master](https://aka.ms/jenkins-on-azure) on Azure
2. Connect to the server with SSH and install the build tools:
   ```
   sudo apt-get install git maven docker.io
   ```
3. Install the plugins in Jenkins. Click 'Manage Jenkins' -> 'Manage Plugins' -> 'Available', then search and install the following plugins: EnvInject, Azure App Service Plugin.
4. Add a Credential in type "Microsoft Azure Service Principal" with your service principal.
5. Add a Credential in type "Username with password" with your account of docker registry.

### Create job

1. Add a new job in type "Pipeline".
2. Enable "Prepare an environment for the run", and put the following environment variables
   in "Properties Content":
    ```
    AZURE_CRED_ID=[your credential id of service principal]
    RES_GROUP=[your resource group of the web app]
    WEB_APP=[the name of the web app]
    ACR_SERVER=[your address of azure container registry]
    ACR_CRED_ID=[your credential id of ACR account]
    DOCUMENTDB_URI=[your documentdb uri]
    DOCUMENTDB_KEY=[your documentdb key]
    DOCUMENTDB_DBNAME=[your documentdb databasename]
    ```
3. Choose "Pipeline script from SCM" in "Pipeline" -> "Definition" or use [Jenkinsfile](./Jenkinsfile)
4. Fill in the SCM repo url and script path."https://github.com/almw/WebApplicationDemoSecurityScan.git" branch "master"

## Build and Deploy Docker Container Image to Azure Web App for Containers

1. Verify you can run your project successfully in your local environment.
2. Run jenkins job.
3. Navigate to the website from your favorite browser. You will see this app successfully running on Azure Web App for Containers.
```bash
# Assumptions, Preexisting Azure Container Registry(ACR) “azurecontainerregistryxxxx101”
docker build . -t azurecontainerregistryxxxx101/webapplicationdemosecurityscan
docker run -it --rm -p  8000:8080 --name webapplicationdemosecurityscan azurecontainerregistryxxxx101/webapplicationdemosecurityscan
# ACR Lodocker login gin
```
### Part 2.1
[Dockerfile](./Dockerfile )
```bash

cat ~/azurecontainerregistryxxxx101.pw | docker login azurecontainerregistryxxxx101.azurecr.io --username azurecontainerregistryxxxx101 -password-stdin
# docker image tagging
docker image tag azurecontainerregistryxxxx101/webapplicationdemosecurityscan:latest azurecontainerregistryxxxx101.azurecr.io/webapplicationdemosecurityscan:latest
# docker image push
docker image push azurecontainerregistryxxxx101.azurecr.io/webapplicationdemosecurityscan:latest
```

### Part 2.2.b
Kubernetes YAML configuration file ["demo-security-context.yaml"](./demo-security-context.yaml) includes securityContext settings.
```bash
# Create the Pod:
kubectl apply -f demo-security-context.yaml
# Verify that the Pod's Container is running:
kubectl get pod demo-security-context
# Get a shell to the running Container:
kubectl exec -it demo-security-context -- sh
ps
```

## Part 3.1 Configuration Management with Terraform
Ref. files
- [providers.tf](./providers.tf)
- [main.tf](./main.tf)
- [variables.tf](./variables.tf)
- [utputs.tf](./outputs.tf)

```sh
terraform init -upgrade
terraform plan -out main.tfplan
terraform apply main.tfplan
terraform destroy

```
Ref. [microsoft.com](https://www.microsoft.com/en-us/)
