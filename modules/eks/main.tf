# IAM Role for EKS cluster

resource "aws_iam_role" "eks-cluster-role" {

  name = "${define-cluster_name}-eks-cluster-role"



  assume_role_policy = jsonencode({

    Version = "2012-10-17",

    Statement = [{

      Action = "sts:AssumeRole",

      Effect = "Allow",

      Principal = {

        Service = "eks.amazonaws.com"

      }

    }]

  })

}


# Attach EKS Cluster Policy to Cluster Role

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = define-cluster-role.name
}



# Create EKS Cluster

resource "aws_eks_cluster" "main-eks-cluster" {
  name     = 
  version  = 
  role_arn = aws_iam_role.eks-cluster-role.arn

  vpc_config {
    subnet_ids = var.subnet_id
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}



# IAM Role for Worker Nodes

resource "aws_iam_role" "eks_node_role" {
  name = "${define-eks-cluster-name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}


# Attach Required Policies to Worker Node Role

resource "aws_iam_role_policy_attachment" "eks_node_policy" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])

  policy_arn = each.value
  role       = aws_iam_role.eks_node_role.name
}


# Create EKS Managed Node Group

resource "aws_eks_node_group" "eks-worker-node" {
  for_each = var.node_groups

  cluster_name    = Add-cluster-name.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.subnet_id

  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type

  scaling_config {
    desired_size = each.value.scaling_config.desired_size
    min_size     = each.value.scaling_config.min_size
    max_size     = each.value.scaling_config.max_size
   
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_policy
  ]
}



