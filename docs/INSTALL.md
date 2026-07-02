# Installation Guide

Install **Terraform**, the **AWS CLI**, and **Git** on your operating system.

> **Version requirement:** Terraform `>= 1.3`.

---

## macOS

```bash
brew install git
brew install tfenv && tfenv install
brew install awscli
```

Verify: `terraform version && aws --version`

---

## Linux

```bash
# Terraform via tfenv
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
tfenv install

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install
```

---

## Windows

```powershell
# Chocolatey (recommended)
choco install terraform awscli git -y

# or winget
winget install HashiCorp.Terraform
winget install Amazon.AWSCLI
winget install Git.Git
```

>  WSL2 lets you use the macOS/Linux instructions as-is.

---

## Configure AWS credentials (all platforms)

```bash
aws configure
# AWS Access Key ID:     <from IAM>
# AWS Secret Access Key: <from IAM>
# Default region name:   us-east-1
# Default output format: json
```

Confirm: `aws sts get-caller-identity`
