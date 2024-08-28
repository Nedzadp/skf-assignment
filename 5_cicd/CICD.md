## CI/CD Task

ADO pipeline is by the default running on Microsoft hosted agent. We can also configure self hosted agent, but we need to manage it infrastructure.
To set specific agent, we use syntax in azure-pipeline.yml:
```
pool:
    name: 'self-hosted-agent-pool'
```

In order to automate complete flow from creating the infrastructure to releasing new code changes I would perform these steps:

1. As mention in description we need to define multiple environments which means multiple infrastructure.
2. To achieve that I would store the terraform state file on remote backend like S3 and use DynamoDb table to prevent locking
3. Each environment dev, qa, staging and production should have define a remote backend configuration and use different s3 buckets and different dynamo db tables.
4. In the terraform code we can include for each env backend.config file which contains configuraiton of s3 remote backend. Then on init provide this file with flag -backend-config.
   
CI/CD pipeline should trigger on each commit to main branch. Commits to branches should perform after PR(pull request) is reviewed and approved for merging to main branch.

After merge to main branch CI/CD pipeline should be automatically triggered.

Each environment deployments will represent one stage in pipeline.

We also need to define pipeline env variables in order to access to AWS.

Each stage will have defined job to run these steps:
1. terraform init & apply for specific env
2. in case application requires environment variable, I would put it inside Azure DevOps secure files library and then in this step override existing .env file in the project
3. docker build image
4. docker push image to aws ecr

One specific env is Production environemnt. Because of sensitivity and such procedure in Continuous Delivery software is always release-ready with manual approval.
Azure ADO enables definition of approval gates. For production stage we can set reviewers who are responsible for approving the stage execution.
To achieve this we need to define approvers (group or user id who can approve the deployment).
In azure-pipeline.yml we need to define ```- approvals``` directive and on Production stage we need to define condition.

In this directory I added also sample how azure-pipeline.yml should look like.