# modules/eks/outputs.tf

output "demo" {
  description = "demo-cluster"
  value = aws_eks_cluster.demo
}