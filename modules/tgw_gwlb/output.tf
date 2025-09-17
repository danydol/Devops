output "Deployment" {
  value = "Finalizing instances configuration may take up to 20 minutes after deployment is finished."
}
output "management_public_ip" {
  depends_on = [module.gwlb]
  value = module.gwlb[*].management_public_ip
}
output "gwlb_arn" {
  depends_on = [module.gwlb]
  value = module.gwlb[*].gwlb_arn
}
output "gwlb_service_name" {
  depends_on = [module.gwlb]
  value = module.gwlb[*].gwlb_service_name
}
output "gwlb_name" {
  value = var.gateway_load_balancer_name
}
output "controller_name" {
  value = "gwlb-controller"
}
output "template_name" {
  value = var.configuration_template
}
/* output "nat_gateway1_id" {
  value = aws_nat_gateway.nat_gateway1.id
}
output "nat_gateway2_id" {
  value = aws_nat_gateway.nat_gateway2.id
}
output "nat_gateway3_id" {
  value = aws_nat_gateway.nat_gateway3.id
} */