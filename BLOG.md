**Midterm Blog**

In this blog, I'm going to walk you through how to deploy a SPA app with a frontend, backend, and MySQL to the cloud manually. The database will be MySQL in a private RDS. We will get a domain name from Name.com and migrate it to Route53 with SSL enabled using Let's Encrypt. Then we will set up an infrastructure repository in GitHub to set up a nightly deployment workflow that will:

- Test the SPA in a temporary EC2 instance
- Perform a smoke test
- On success, create a container image and push it to an ECR
- Deploy the image to a pre-allocated EC2 from the ECR

Let's get started!

---

## **Step 1: Set Up an RDS MySQL Instance**

1. **Log in to AWS Console**
   - Go to your AWS Academy account and launch the AWS Console.

2. **Navigate to RDS**
   - In the AWS Console, search for "RDS" and select it.

3. **Create a Database**
   - Click **Create database**.
   - Choose **Standard create**.
   - Select **MySQL** as the engine.
   - Choose **MySQL 8.0** as the version.

4. **Configure Settings**
   - Select **Free tier** for templates.
   - Set **DB instance identifier**: `fixedstrike`
   - Set **Master username**: `admin`
   - Set a password of your choice.

5. **Instance Configuration**
   - Select **Burstable classes** → `db.t3.micro` (or smallest available).
   - Storage: **20 GB General Purpose SSD**.

6. **Connectivity**
   - VPC: Use **default VPC**.
   - **Additional connectivity configuration**
     - **Public access**: Yes (this will be changed later).
     - **VPC security group**: Create a new one named `fixedstrike-db-sg`.

7. **Additional Configuration**
   - Set **Initial database name**: `fixedstrike`.

8. **Create Database**
   - Click **Create database** and wait 5-10 minutes for completion.

---

## **Step 2: Load Schema/Data into Database**

1. **Export your database schema and data from your local MySQL database**
   - Use `mysqldump` to export your database into SQL files.

2. **Import to AWS RDS MySQL instance**
   - Use `fixedstrike_schema.sql` and `fixedstrike_data.sql` from the repository.
   - Replace `your-rds-endpoint.rds.amazonaws.com` with your actual RDS endpoint.

3. **Alternative Authentication**
   - Use **DBeaver** if authentication plugin issues occur.
   - Set up a **New Database Connection** in DBeaver and import schema/data.

---

## **Step 3: Create an EC2 Instance for Your Application**

1. **Navigate to EC2 in AWS Console**
2. **Launch a new EC2 instance**
   - Name: `fixedstrike-qa-instance`
   - Select **Amazon Linux 2023 AMI**
   - Choose `t2.micro` (free tier eligible)
   - Create a key pair: `fsv-key`
   - **Network settings**:
     - Create a security group: `fsv-app-sg`
     - Add inbound rules:
       - SSH (22) from your IP
       - HTTP (80) from anywhere
       - HTTPS (443) from anywhere

3. **Configure Storage**
   - Default 8 GB is sufficient.

4. **Add User Data Script**
   - Install Docker, AWS CLI, and Certbot for SSL setup.

5. **Launch the instance**
   - Click **Launch instance**.

---

## **Step 4: Make RDS Private & Secure Connection to EC2**

1. **Modify RDS to be Private**
   - Go to RDS → Select `fixedstrike` → Click **Modify** → Set **Not publicly accessible**.

2. **Update RDS Security Group**
   - Navigate to **EC2 Security Groups** → Edit `fixedstrike-db-sg` → Allow **MySQL (3306) access from the EC2 instance's security group**.

---

## **Step 5: Create an ECR Repository for Docker Images**

1. Navigate to **ECR** in AWS Console.
2. Click **Create Repository**.
3. Name it `fsv-app` and click **Create**.
4. **Save the Repository URI**.

---

## **Step 6: Build and Push Docker Image**

1. **Authenticate AWS CLI**
   - `$ aws configure`
   - `$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com`

2. **Build and Tag Docker Image**
   - `$ docker buildx build --platform linux/amd64,linux/arm64 -t <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/fsv-app:latest . --push`

3. **Push Image to ECR**
   - `$ docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/fsv-app:latest`

---

## **Domain Name Setup and SSL Configuration**

### **Part 1: Domain Name Setup**

1. **Purchase a Domain** from Name.com.
2. **Migrate Domain to Route53**.
   - Create a **public hosted zone** in Route53.
   - Update Name.com DNS records with AWS Name Servers.

### **Part 2: SSL Configuration with Let's Encrypt**

1. **Update DNS A Records in Route53**
2. **Install Nginx on EC2**
3. **Configure Nginx for SSL**
4. **Use Certbot to Obtain SSL Certificate**

---

## **Step 7: Automate Deployment with GitHub Actions**

1. **Create a GitHub Actions Workflow**
   - Set up an **infrastructure repository**.
   - Generate a **Personal Access Token (PAT)**.
   - Store **AWS credentials and database credentials** as GitHub secrets.

2. **Define Workflow in `.github/workflows/nightly-qa-deployment.yml`**
   - **Triggers at 2 AM UTC daily**.
   - **Builds and pushes Docker images to ECR**.
   - **Deploys to a test EC2 instance and runs smoke tests**.
   - **Promotes successful images and deploys to QA**.

3. **Test & Verify the Deployment**
   - Manually trigger the workflow in GitHub Actions.
   - Verify **EC2 instance runs the latest container**.
   - Ensure the application is accessible.

---

Now you can access the application via its **domain name with SSL encryption**! This setup ensures a robust cloud deployment pipeline with automation and security best practices in place.

