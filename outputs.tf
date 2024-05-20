
output "route53_resolver_rule_arns" {
  description = "Rule ARNs"
  value       = aws_route53_resolver_rule.r.*.arn
}

output "route53_resolver_rule_ids" {
  description = "Rule IDs"
  value       = aws_route53_resolver_rule.r.*.id
}

output "route53_resolver_rule_share_status" {
  description = "Rule ARNs"
  value       = aws_route53_resolver_rule.r.*.share_status
}
