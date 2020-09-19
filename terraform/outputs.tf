output "swarm_managers" {
  value = "${concat(aws_instance.managers.*.public_dns)}"
}

output "swarm_nodes" {
  value = "${concat(aws_instance.workers.*.public_dns)}"
}