output "controller" {
  value = aws_instance.controller
}

output "workers" {
  value = aws_instance.workers
}

output "instance_ids" {
  description = "All k0s EC2 instance IDs (controller + workers)"
  value = concat(
    [aws_instance.controller.id],
    aws_instance.workers[*].id
  )
}
