resource "aws_opensearch_domain" "wsi_opensearch" {
  domain_name    = "wsi-opensearch"
  engine_version = "OpenSearch_2.13"

  cluster_config {
    instance_type            = "r5.large.search"
    instance_count           = 2
    dedicated_master_enabled = true
    dedicated_master_type    = "r5.large.search"
    dedicated_master_count   = 3
    zone_awareness_enabled   = true            # Enable zone awareness for 2-AZ deployment
    zone_awareness_config {
      availability_zone_count = 2              # Set the number of AZs to 2
    }
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false    # Disable anonymous authentication
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "admin"
      master_user_password = "Password01!"
    }
  }

  encrypt_at_rest {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  node_to_node_encryption {
    enabled = true
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
  }

  # Fine-grained access control only
  access_policies = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : "es:*",
        "Resource" : "arn:aws:es:ap-northeast-2:${data.aws_caller_identity.current.account_id}:domain/wsi-opensearch/*"
      }
    ]
  })

  tags = {
    Name = "wsi-opensearch"
  }
}

output "opensearch_endpoint" {
  value = aws_opensearch_domain.wsi_opensearch.endpoint
}