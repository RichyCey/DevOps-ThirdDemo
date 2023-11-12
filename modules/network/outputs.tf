# modules/network/outputs.tf

output "private-us-east-1a" {
  description = "private-us-east-1a subnet ID"
  value       = aws_subnet.private-us-east-1a.id
}

output "private-us-east-1b" {
  description = "private-us-east-1b subnet ID"
  value       = aws_subnet.private-us-east-1b.id
}

output "public-us-east-1a" {
  description = "public-us-east-1a subnet ID"
  value       = aws_subnet.public-us-east-1a.id
}

output "public-us-east-1b" {
  description = "public-us-east-1b subnet ID"
  value       = aws_subnet.public-us-east-1b.id
}