

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# All PUBLIC subnets in default VPC (default + custom, across AZs)
data "aws_subnets" "default_vpc_public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]  # Public subnets only ✓
  }
}

locals {
  public_subnet_ids = data.aws_subnets.default_vpc_public_subnets.ids
}

# Debug: Check subnets and their AZs
output "selected_subnets" {
  value = {
    count = length(local.public_subnet_ids)
    ids   = local.public_subnet_ids
    ids   = data.aws_subnets.default_vpc_public_subnets.ids
  }
}

output "subnets_by_az" {
  value = {
    for subnet_id, subnet in data.aws_subnet.default_vpc_public : subnet.availability_zone => subnet.id
  }
}

# Get detailed subnet info for AZ mapping
data "aws_subnet" "default_vpc_public" {
  for_each = toset(local.public_subnet_ids)

  id = each.value
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# Security Group for Control Plane
resource "aws_security_group" "eks_cluster" {
  name_prefix = "eks-cluster-"
  vpc_id      = data.aws_vpc.default.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-cluster-sg"
  }
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "my-single-eks-native"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.31"

  vpc_config {
    subnet_ids              = local.public_subnet_ids  # All public subnets (2+ AZs)
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = false
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# IAM Role for Worker Nodes
resource "aws_iam_role" "eks_nodes" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# Node Security Group
resource "aws_security_group" "eks_nodes" {
  name_prefix = "eks-node-"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "kubernetes.io/cluster/${aws_eks_cluster.main.name}" = "owned"
  }
}

# EKS Managed Node Group
resource "aws_eks_node_group" "private" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "single-nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = local.public_subnet_ids

  instance_types = ["t3.small"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry,
  ]

  tags = {
    "kubernetes.io/cluster/${aws_eks_cluster.main.name}" = "owned"
  }
}

# Outputs
output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --region us-east-1 --name ${aws_eks_cluster.main.name}"
}
