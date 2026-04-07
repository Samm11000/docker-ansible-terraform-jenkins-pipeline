# Task API — Full DevOps CI/CD Pipeline

> **A production-grade CI/CD pipeline** that automatically builds, pushes, and deploys a Node.js REST API to AWS EC2 — triggered by a single `git push`.

<img width="1536" height="1024" alt="CI_CD pipeline for Task API" src="https://github.com/user-attachments/assets/eebbbb45-d60b-4c87-9741-3a0e5b1c6603" />


---

## Pipeline Flow

```
Developer pushes code
        │
        ▼
  GitHub Webhook
        │
        ▼
   Jenkins CI/CD
  ┌─────────────────────────────────┐
  │  1. Checkout SCM                │
  │  2. Build Docker Image          │
  │  3. Push to Docker Hub          │
  │  4. Deploy with Ansible         │
  │  5. Health Check                │
  └─────────────────────────────────┘
        │
        ▼
  AWS EC2 — Live App 🚀
```

---

## Tech Stack

| Tool          | Purpose                                          |
|---------------|--------------------------------------------------|
| **Docker**    | Containerize the Node.js app with multi-stage build |
| **Terraform** | Provision AWS EC2 infrastructure as code         |
| **Ansible**   | Configure servers & deploy Docker container      |
| **Jenkins**   | End-to-end CI/CD pipeline automation             |
| **Docker Hub**| Store and version Docker images                  |
| **AWS EC2**   | Cloud servers (free tier t2.micro)               |
| **Nginx**     | Reverse proxy in front of Node.js app            |

---

## How It Works

1. Developer pushes code to the `main` branch on GitHub
2. GitHub webhook triggers the Jenkins pipeline automatically
3. Jenkins checks out the code and builds a fresh Docker image
4. The image is tagged with the build number and pushed to Docker Hub
5. Jenkins calls Ansible, which SSHs into the EC2 app server
6. Ansible pulls the new image and restarts the container with zero downtime
7. Jenkins pings the `/health` endpoint to confirm the app is live

---

## Jenkins Pipeline Stages

![Jenkins Pipeline — Build #11 succeeded in 1m 4s](app.jpeg)

*All 7 stages passing: Checkout SCM → Checkout → Build Docker → Push to Docker Hub → Deploy with Ansible → Health Check → Post Actions*

---

## Project Structure

```
task-api-devops/
├── README.md
├── Jenkinsfile                  ← Pipeline as code
├── Dockerfile                   ← Multi-stage Docker build
├── docker-compose.yml           ← App + Nginx orchestration
├── nginx.conf                   ← Reverse proxy config
├── app.js                       ← Node.js REST API
├── package.json
├── terraform/
│   ├── main.tf                  ← EC2, Security Groups
│   ├── variables.tf
│   └── outputs.tf               ← Prints server IPs
└── ansible/
    ├── inventory.ini            ← Server IP list
    ├── deploy.yml               ← Main deployment playbook
    └── secrets.yml              ← Ansible Vault encrypted secrets
```

---

## Prerequisites

Before you begin, make sure you have:

- AWS Account (free tier is enough)
- Docker & Docker Compose installed locally
- Terraform installed (`terraform --version`)
- Ansible installed (`ansible --version`)
- Jenkins server — either on EC2 or local
- Docker Hub account (free at hub.docker.com)
- AWS CLI configured (`aws configure`)

---

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/task-api-devops.git
cd task-api-devops
```

---

### 2. Provision Infrastructure with Terraform

```bash
cd terraform
terraform init          # Download provider plugins (first time only)
terraform plan          # Preview what will be created
terraform apply         # Create servers on AWS — type "yes" when prompted
```

**This creates:**
- App Server (EC2 t2.micro) — runs your Docker container
- Jenkins Server (EC2 t2.micro) — runs the CI/CD pipeline
- Security Group — allows SSH (22), HTTP (80), Jenkins (8080)

After apply, note the output IPs:
```
app_server_ip     = "13.235.xx.xx"
jenkins_server_ip = "13.126.xx.xx"
```

> **Cost:** $0 on AWS free tier. Run `terraform destroy` when not in use.

---

### 3. Configure Servers with Ansible

Update `ansible/inventory.ini` with your actual EC2 IPs from the Terraform output:

```ini
[app_servers]
13.235.xx.xx  ansible_user=ubuntu  ansible_ssh_private_key_file=~/.ssh/your-key.pem
```

Then run the playbook:

```bash
cd ansible
ansible-playbook -i inventory.ini deploy.yml --ask-vault-pass
```

**This automatically:**
- Installs Docker on the app server
- Pulls your Docker image from Docker Hub
- Starts the container with `restart_policy: always`

---

### 4. Set Up Jenkins

**Access Jenkins:**
```
http://<JENKINS-IP>:8080
```

Get the initial admin password:
```bash
ssh -i ~/.ssh/your-key.pem ubuntu@<JENKINS-IP>
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Add required credentials** (Dashboard → Manage Jenkins → Credentials → Add):

| Credential ID       | Type                  | Value                    |
|---------------------|-----------------------|--------------------------|
| `dockerhub-creds`   | Username with password | Your Docker Hub login    |
| `ssh-key`           | SSH Username with key  | Your EC2 private key     |

---

### 5. Create Jenkins Pipeline

1. New Item → **Pipeline** → name it `task-api-pipeline`
2. Under **Pipeline**:
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: your GitHub repo URL
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
3. Check **"GitHub hook trigger for GITScm polling"**
4. Click **Save**

---

### 6. Configure GitHub Webhook

Go to your GitHub repo → **Settings** → **Webhooks** → **Add webhook**:

```
Payload URL:  http://<JENKINS-IP>:8080/github-webhook/
Content type: application/json
Events:       Just the push event
```

> After this, every `git push` to `main` triggers the full pipeline automatically.

---

### 7. Trigger Your First Deployment

```bash
git add .
git commit -m "initial deployment"
git push origin main
```

Watch Jenkins run the pipeline. All stages should turn green in ~1–2 minutes.

---

### 8. Verify the App is Live

**Check the API:**
```bash
curl http://<APP-SERVER-IP>/tasks
```

Expected response:
```json
[
  { "id": 1, "title": "Learn Docker" },
  { "id": 2, "title": "Learn Ansible" }
]
```

**Health check:**
```bash
curl http://<APP-SERVER-IP>/health
```

Expected response:
```json
{ "status": "OK" }
```

---

## API Endpoints

| Method | Endpoint  | Description         |
|--------|-----------|---------------------|
| GET    | `/tasks`  | Get all tasks       |
| POST   | `/tasks`  | Create a new task   |
| GET    | `/health` | Health check        |

**Example — create a task:**
```bash
curl -X POST http://<APP-SERVER-IP>/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Terraform"}'
```

---

## Security Practices Used

- **Ansible Vault** — all secrets (DB passwords, API tokens) are encrypted at rest
- **Jenkins Credentials Store** — Docker Hub credentials never exposed in code
- **AWS Security Groups** — ports restricted to only what is needed
- **SSH Key Auth** — password login disabled on all EC2 instances
- **Terraform Remote State** — state stored in S3 with DynamoDB lock to prevent conflicts

---

## Cleanup

To destroy all AWS resources when done:

```bash
cd terraform
terraform destroy
```

> Type `yes` when prompted. This removes both EC2 instances and the security group.

---

## What I Learned

- Writing **Dockerfiles** with multi-stage builds and layer caching
- Provisioning **AWS infrastructure as code** with Terraform modules, remote state, and outputs
- Automating **server configuration** with idempotent Ansible playbooks and Vault-encrypted secrets
- Building a complete **declarative Jenkins pipeline** (Jenkinsfile) with GitHub webhook integration
- Connecting all four tools into a single automated workflow: code → test → build → push → deploy → verify

---

## Author

Built as a hands-on DevOps learning project covering the full CI/CD lifecycle.
Feel free to fork, star, and use this as a reference for your own pipeline!
