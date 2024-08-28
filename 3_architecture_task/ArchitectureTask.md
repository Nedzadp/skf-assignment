## Architecture task
Written explanation of the diagram components, operation and dataflow:

We need to make decision which region to use to deploy infrastructure.

### 1. ECR
First step is to create ECR repository where we will store docker image of the app.
### 2. VPC
Then we create new VPC with at least two public subnets with different AZ to ensure high availability and fault tolerance of the resources.
### 3. ECS
Next step is to create ECS cluster. After creation of ECS cluster we proceed with creation of task definition.
Task definition will define which docker image to use from the ECR. That's why on diagram we can see arrow from task definition to ECR. Task definition execution role has a permission to get image from ECR.
Next step is to create ECS service. When defining ECS service we choose launch type FARGATE.
Since we want our app running all the type we will setup application type to be service.
In ECS service we will point to already created task definition.
ECS service should select VPC and subnets created in step 1.
In ECS service creation step we also define load balancer. New application load balancer is created and new target group is created.
In ECS service we can also define number of tasks to run. Each task represent containers defined in task definition.
ECS service creation can also define scalling policy, but for the assignment purpose this is skipped.

### 4. Security Groups
Create security group for the ALB and allow access from any IP.
We define new security group for the ECS service to only allow access from the security group of the ALB. 

### API Access

In order to access to our service application load balancer is exposed to public. 
Application load balancer after receiving the request will route the request to appropriate service task in ECS cluster.


### First run

On first run all AWS component should be created. But, since we didn't push any docker image to ECR then ECS service deployment will fail.
Pushing docker image to ECR and updating ECS service should be done through CI/CD pipeline.
After service is updated ECS cluster should pull image and start the container.

