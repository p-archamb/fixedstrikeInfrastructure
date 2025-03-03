# Midterm Blog

In this blog, I'm going to walk you through how to deploy a SPA app with a frontend, backend, and MySQL to the cloud manually. The database will be MySQL in a private RDS. We will get a domain name from Name.com and migrate it to Route53 with SSL enabled using LetsEncrypt. Then, we will set up an infrastructure repository in GitHub to establish a nightly deployment workflow that will test the SPA in a temporary EC2, perform a smoke test, and upon success, create a container image and push it to an ECR. The image will then be deployed to a pre-allocated EC2 from the ECR. Let's get started!

## Clone the Repository

```
git clone https://github.com/p-archamb/FixedStrikeVolatility
```

## Test the Application Locally

Run the following command in the terminal:

```
docker compose up
```

This command will use the Docker files and should display the app as shown below. To see the application, open a browser and visit:

```
localhost:8081
```
![Alt text](Picture2.png)
Great! Now that the application is working, let’s get it running in the cloud!

---

# Step 1: Set Up an RDS MySQL Instance

1. **Log in to AWS Console**
   - Go to your AWS Academy account and launch the AWS Console.
2. **Navigate to RDS**
   - Search for "RDS" in the AWS Console and select it.
3. **Create a Database**
   - Click "Create database."
   - Choose "Standard create."
   - Under Engine options, select "MySQL."
   - Choose MySQL 8.0 as the version.
4. **Configure Settings**
   - Select "Free tier."
   - Set DB instance identifier: `fixedstrike.`
   - Set Master username: `admin.`
   - Create and confirm a password.
5. **Instance Configuration**
   - Select "Burstable classes" then `db.t3.micro` (or smallest available).
   - Storage: 20 GB General Purpose SSD (minimum).
6. **Connectivity**
   - Use default VPC.
   - Set "Public access" to **Yes** (for initial configuration).
   - Create a new VPC security group: `fixedstrike-db-sg.`
7. **Additional Configuration**
   - Initial database name: `fixedstrike.`
8. **Create Database**
   - Click "Create database."
   - Wait 5-10 minutes for database creation.

---

# Step 2: Load Schema/Data into Database

1. **Export your local MySQL database schema and data**
   - Use `mysqldump` to export the database into SQL files.
2. **Import to your AWS RDS MySQL instance**
   - Use `fixedstrike_schema.sql` and `fixedstrike_data.sql` from the repository.
   - Replace `your-rds-endpoint.rds.amazonaws.com` with your actual RDS endpoint.
3. **Handling Authentication Plugin Issues**
   - If you encounter authentication errors, use **DBeaver** to connect to the RDS instance instead of the command line.

---

# Step 3: Create an EC2 Instance for Your Application

1. **Navigate to EC2**
   - Go to the EC2 service in the AWS Console.
2. **Launch an Instance**
   - Click "Launch instances."
   - Name: `fixedstrike-qa-instance.`
3. **Select AMI**
   - Choose "Amazon Linux 2023" AMI.
4. **Instance Type**
   - Select `t2.micro` (free tier eligible).
5. **Key Pair**
   - Create a new key pair (`fsv-key.pem`).
6. **Network Settings**
   - Create a new security group (`fsv-app-sg`).
   - Add inbound rules for **SSH (22), HTTP (80), and HTTPS (443).**
7. **Configure Storage**
   - Default 8 GB is sufficient.
8. **User Data (Bootstrap Script)**
   - Install Docker, Docker Compose, AWS CLI, and Certbot for SSL.

---

# Step 4: Make RDS Private and Set EC2 Connection

1. **Modify RDS to Private**
   - Go to RDS > Select `fixedstrike-db` > Click "Modify."
   - Set "Not publicly accessible."
2. **Update Security Groups**
   - Allow MySQL/Aurora (3306) access from the EC2 security group.

---

# Step 5: Create ECR Repository for Docker Images

1. **Navigate to ECR** in AWS Console.
2. **Create a repository:**
   - Name it `fsv-app.`
   - Note the **Repository URI** for later use.

---

# Step 6: Build and Push Docker Image

1. **Configure AWS CLI**
   ```
   aws configure
   aws configure set aws_session_token 'session_token'
   ```
2. **Authenticate to ECR**
   ```
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
   ```
3. **Build and Push Image**
   ```
   docker buildx build --platform linux/amd64,linux/arm64 -t YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/fsv-app:latest . --push
   docker push YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/fsv-app:latest
   ```
4. **Deploy to EC2**
   ```
   ssh -i your-key.pem ec2-user@YOUR_EC2_PUBLIC_IP
   docker-compose up -d
   ```

---

# Domain Name Setup and SSL Configuration

### Part 1: Domain Name Setup

1. Purchase a domain on **Name.com.**
2. Migrate the domain to **Route53.**
   - Update Name.com to use AWS Route53 name servers.

### Part 2: SSL Configuration with Let's Encrypt

1. **Update DNS A Records in Route53** to point to EC2’s public IP.
2. **Install and Configure Nginx.**
3. **Obtain SSL Certificate using Certbot.**
   ```
   sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
   ```
4. **Set up Auto-renewal.**
   ```
   sudo certbot renew --dry-run
   sudo crontab -e
   0 0,12 * * * certbot renew --quiet
   ```

---

# Infrastructure Repository & Deployment