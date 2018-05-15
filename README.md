# Setup instructions for running Wordpress on GKE

## Networking Setup

gcloud compute --project={project} networks create wordpress --mode=custom

gcloud compute --project={project} networks subnets create wordpress-australia-southeast1 --network=wordpress --region=australia-southeast1 --range=10.0.0.0/9

## Setup Service Accounts

Easiest to create these through the WebUI for now...

Create wordpress-cloudsql-proxy and assign "Cloud SQL\SQL Client" role.
Create wordpress-storage and assign "Cloud Storage Admin" role.
Furnish a new private key and download the JSON file.

## Cloud Storage

gsutil mb -c  regional -l australia-southeast1 -p {project} gs://{project}-wordpress

## Base Kubernetes Seutp

gcloud beta container --project "{project}" clusters create wordpress-cluster --zone "australia-southeast1-a" --username "admin" --cluster-version "1.8.8-gke.0" --machine-type "n1-standard-1" --image-type "COS" --disk-size "100" --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "3" --network "wordpress" --enable-cloud-logging --enable-cloud-monitoring --subnetwork "wordpress-australia-southeast1" --enable-autoscaling --min-nodes "3" --max-nodes "10" --addons HorizontalPodAutoscaling,HttpLoadBalancing,KubernetesDashboard --enable-autorepair

## Cloud SQL Setup

gcloud sql instances create wordpress-sql --tier=db-n1-standard-1 --region=australia-southeast1

-- lookup the instance name like {project}:{region}:{instance name}

gcloud sql users set-password root % --instance wordpress-sql --password {password}

gcloud sql users create proxyuser cloudsqlproxy~% --instance=wordpress-sql --password={password}

## Deploy Wordpress on Kubernetes

First - check mysql-wordpress-deployment.yaml and make sure the references point to your project, image, Cloud SQL URL, etc.

Then.

kubectl create secret generic cloudsql-instance-credentials --from-file=credentials.json=wordpress-gke-cloudsql.json

kubectl create secret generic cloudsql-db-credentials --from-literal=username=proxyuser --from-literal=password={password}

### Build custom Wordpress image

docker pull wordpress:latest

docker build -t gcr.io/{project}/wordpress-custom:v1.0 .

docker push gcr.io/{project}/wordpress-custom:v1.0 .

### Deploy!

kubectl apply -f mysql-wordpress-deployment.yaml

kubectl apply -f mysql-wordpress-service.yaml

# Git Submodule

The WP plugins are referencing other github repositories.  Check this gist out for working with submodules https://gist.github.com/gitaarik/8735255