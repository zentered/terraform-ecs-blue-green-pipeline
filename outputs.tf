output "website_endpoint" {
  value = aws_lb.lb.dns_name
}
