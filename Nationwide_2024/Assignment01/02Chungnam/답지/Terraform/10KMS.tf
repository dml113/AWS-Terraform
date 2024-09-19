resource "aws_kms_key" "eks_kms_key" {
  description = "EKS KMS key for secrets encryption"
}

resource "aws_kms_alias" "eks_kms_alias" {
  name          = "alias/eks-kms-key"
  target_key_id = aws_kms_key.eks_kms_key.id
}