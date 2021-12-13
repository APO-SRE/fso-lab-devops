# Providers ----------------------------------------------------------------------------------------
provider "aws" {
  region  = var.aws_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Locals -------------------------------------------------------------------------------------------
locals {
  # format current date for convenience.
  current_date = formatdate("YYYY-MM-DD", timestamp())

  # create formatted hostname and resource prefixes with lab number.
  lab_hostname_prefix = var.lab_number > 0 ? format("%s-%02d", var.aws_ec2_vm_hostname_prefix, var.lab_number) : var.aws_ec2_vm_hostname_prefix
  lab_resource_prefix = var.lab_number > 0 ? format("%s-%02d", var.resource_name_prefix, var.lab_number) : var.resource_name_prefix

  # eks cluster name defined here so it can be referenced in other resources.
# cluster_name = "${local.lab_resource_prefix}-${lower(random_string.suffix.result)}-eks-cluster"
  cluster_name = "${local.lab_resource_prefix}-${local.current_date}-EKS"
}

# Data Sources -------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {
}

data "aws_availability_zones" "available" {
}

data "aws_ami" "fso_lab_ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name = "name"
    values = [var.aws_ec2_source_ami_filter]
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

# Modules ------------------------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 3.11"

# name = "${local.lab_resource_prefix}-${lower(random_string.suffix.result)}-vpc"
  name = "${local.lab_resource_prefix}-${local.current_date}-VPC"
  cidr = var.aws_vpc_cidr_block

  azs             = data.aws_availability_zones.available.names
  public_subnets  = var.aws_vpc_public_subnets
  private_subnets = var.aws_vpc_private_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = var.resource_tags

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = ">= 4.7"

# name        = "${local.lab_resource_prefix}-${lower(random_string.suffix.result)}-security-group"
  name        = "${local.lab_resource_prefix}-${local.current_date}-Security-Group"
  description = "Security group for LPAD VM EC2 instance"
  vpc_id      = module.vpc.vpc_id
  tags        = var.resource_tags

  ingress_cidr_blocks               = ["0.0.0.0/0"]
  ingress_rules                     = ["http-80-tcp", "http-8080-tcp", "https-443-tcp", "all-icmp"]
  egress_rules                      = ["all-all"]
  ingress_with_self                 = [{rule = "all-all"}]
  computed_ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow SSH access."
      cidr_blocks = var.aws_ssh_ingress_cidr_blocks
    },
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Allow TCP traffic from Cisco data center."
      cidr_blocks = var.cisco_tcp_ingress_cidr_blocks
    }
  ]
  number_of_computed_ingress_with_cidr_blocks = 2
}

module "vm" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = ">= 3.3"

# name                 = "${local.lab_resource_prefix}-${lower(random_string.suffix.result)}-vm"
  name                 = "${local.lab_resource_prefix}-${local.current_date}-VM"
  ami                  = data.aws_ami.fso_lab_ami.id
  instance_type        = var.aws_ec2_instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.id
  key_name             = var.aws_ec2_ssh_pub_key_name
  tags                 = var.resource_tags

  subnet_id                   = tolist(module.vpc.public_subnets)[0]
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = true

  user_data_base64 = base64encode(templatefile("${path.module}/templates/user-data-sh.tmpl", {
    aws_ec2_user_name    = var.aws_ec2_user_name
    aws_ec2_hostname     = "${local.lab_hostname_prefix}-vm"
    aws_ec2_domain       = var.aws_ec2_domain
    aws_region_name      = var.aws_region
    aws_eks_cluster_name = local.cluster_name
  }))
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 17.24"

  cluster_name    = local.cluster_name
  cluster_version = var.aws_eks_kubernetes_version
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets

  cluster_endpoint_public_access       = var.aws_eks_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.aws_eks_endpoint_public_access_cidrs

  tags = var.resource_tags

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 80
  }

  node_groups = {
    "node-group" = {
      desired_capacity = var.aws_eks_desired_node_count
      min_capacity     = var.aws_eks_min_node_count
      max_capacity     = var.aws_eks_max_node_count
      instance_types   = var.aws_eks_instance_type
      key_name         = var.lab_ssh_pub_key_name

      k8s_labels = {
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }

      additional_tags = var.resource_tags
    }
  }

  map_roles = [
    {
      rolearn  = aws_iam_role.ec2_access_role.arn
      username = "fsolabuser"
      groups   = ["system:masters"]
    }
  ]

# map_users    = var.map_users
# map_accounts = var.map_accounts
}

# Resources ----------------------------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 5
  special = false
}

resource "aws_iam_role" "ec2_access_role" {
# name               = "${local.lab_resource_prefix}-${lower(random_string.suffix.result)}-ec2-access-role"
  name               = "${local.lab_resource_prefix}-${local.current_date}-EC2-Access-Role"
  assume_role_policy = file("${path.module}/policies/ec2-assume-role-policy.json")
  tags               = var.resource_tags
}

resource "aws_iam_role_policy" "ec2_access_policy" {
# name   = "${local.lab_resource_prefix}-${lower(random_string.suffix.result)}-ec2-access-policy"
  name   = "${local.lab_resource_prefix}-${local.current_date}-EC2-Access-Policy"
  role   = aws_iam_role.ec2_access_role.id
  policy = file("${path.module}/policies/ec2-access-policy.json")
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
# name = "${local.lab_resource_prefix}-${lower(random_string.suffix.result)}-ec2-instance-profile"
  name = "${local.lab_resource_prefix}-${local.current_date}-EC2-Instance-Profile"
  role = aws_iam_role.ec2_access_role.name
}

resource "null_resource" "kubectl_trigger" {
  # fire the trigger when the eks cluster requires re-provisioning.
  triggers = {
    eks_cluster_id = module.eks.cluster_id
  }

  # run 'kubectl' to retrieve the kubernetes config when the eks cluster is ready.
  provisioner "local-exec" {
    working_dir = "."
    command = "aws eks --region ${var.aws_region} update-kubeconfig --name ${local.cluster_name}"
  }
}

resource "null_resource" "ansible_trigger" {
  # fire the ansible trigger when the ec2 vm instance requires re-provisioning.
  triggers = {
    ec2_instance_ids = module.vm.id
  }

  # execute the following 'local-exec' provisioners each time the trigger is invoked.
  # generate the ansible aws hosts inventory.
  provisioner "local-exec" {
    working_dir = "."
    command     = <<EOD
cat <<EOF > aws_hosts.inventory
[fso_lab_vm]
${module.vm.public_dns}
EOF
EOD
  }
}
