# ECS Web Application Proof of Concept

## Deploy it yourself

### Prerequisites

- An AWS account
- A Docker Hub account
- A Github account

### Instructions

1. Fork this repository to your GitHub account.

1. Sign in to Docker Hub.  Click on your account name in the top right-hand corner, and go to `Account Settings` > `Security`.  Click the New Access Token button, and add a description to create a Personal Access Token.  We'll need this later.

1. Sign in to AWS.  Go to `IAM` > `Users`, and click `Add user`.  Select `Programmatic access` under `Access type`. Go to the next step, and select `Attach existing policies directly`.  Attach the `AdministratorAccess` policy, and then click through to review and create the user.  We'll need the access key ID and secret token in the next step.

1. In your Github repository, go to `Settings` > `Secrets`.  Using the `New secret` button, create the following four secrets:

    ```
    Name: AWS_ACCESS_KEY_ID
    Value: The ID portion of your AWS access key (all caps)

    Name: AWS_SECRET_ACCESS_KEY
    Value: The Secret Key portion of your AWS access key

    Name: DOCKER_HUB_USERNAME
    Value: Your Docker Hub username

    Name: DOCKER_HUB_PAT
    Value: The Docker Hub access token that you created earlier
    ```

1. Run the pipeline to see the build results.  Github is currently in the process of adding support for manually running pipelines - until this is added, you may need to push a commit with a newline added to a file to get the project to build.  The project will be deployed into the `ap-southeast-2` region of your AWS account.

## Infrastructure

This proof of concept deploys a Dockerised web application written in Go to AWS ECS using Fargate.  Fargate tasks are split across two subnets in different availability zones to increase reliability.  Incoming traffic is handled by a load balancer and an Internet gateway, and the application scales from a minimum of two tasks to a maximum of 10 when the CPU load on the Fargate tasks hits 70%.  The infrastructure is built out as code using CloudFormation templates, and the Dockerised application is hosted on Docker Hub.

## CI/CD

I chose to use [Github Actions](https://github.com/features/actions) for CI/CD for several reasons.  Firstly, anyone who has access to the Github repository can view the output of the CI/CD pipeline without needing to manage extra permissions.  Github Actions also allows users to manage secrets from within a repository, and has good protection against secret leakage and logging.  Github Actions also integrates well with both Docker and AWS - the AWS CLI is installed on Github-hosted agents by default, and both AWS and Docker maintain actions for the workflows that I needed to use.

## Scaling

The scaling rule for this application is managed by the CloudFormation template.  The desired, minimum, and maximum task counts, as well as the target CPU usage for the scaling rule, are stored in  parameters at the top of the CloudFormation template.  If you want to change the task counts or scaling rules, you can either change the variables in the CloudFormation template or pass in your own values when you deploy the template.  (This will overwrite the default values specified.)

## Tradeoffs, Limitations, and Improvements

- I used an IAM user with full admin permissions for the deployment, so that I didn't have to worry about going in and tweaking the policies.  In order to secure the build and deployment process further, I would reduce the number of permissions on the IAM user once I was sure that the infrastructure itself worked well.
- The AWS region that the Github Actions pipeline uses is currently hard-coded.  As part of general cleanup, I would pull this out into a separate variable in case it needed to be re-used.
- I chose to use Fargate rather than EC2 because scaling with Fargate is more intuitive.  For a production application, I would want to do a cost-benefit analysis of Fargate vs. EC2.  However, with the addition of Compute Savings Plans that can be applied to Fargate tasks in late 2019, I've generally found that the cost of Fargate is comparable to, or lower than, the cost of running workloads on EC2, unless the EC2 workloads are running at very high utilisation (>85%).
- It would also be possible to have the Fargate tasks scale out on other metrics - I chose to use CPU usage because it's easily testable for a proof of concept.  For a production application, different scaling metrics (or even custom metrics) might be more appropriate.