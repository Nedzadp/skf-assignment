output "cluster_name" {
  value = aws_ecs_cluster.flask-cluster.name
}

output "alb_domain_name" {
  value = aws_lb.flask-alb.dns_name
}