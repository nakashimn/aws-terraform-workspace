################################################################################
# Cloudfront
################################################################################
resource "aws_cloudfront_distribution" "documents" {
    origin {
        domain_name = aws_s3_bucket.documents.bucket_regional_domain_name
        origin_id = aws_s3_bucket.documents.id
        origin_access_control_id = aws_cloudfront_origin_access_control.documents.id
    }

    default_root_object = "index.html"
    enabled             =  true
    web_acl_id          = aws_wafv2_web_acl.documents.arn

    default_cache_behavior {
        allowed_methods = [ "GET", "HEAD" ]
        cached_methods = [ "GET", "HEAD" ]
        target_origin_id = aws_s3_bucket.documents.id

        forwarded_values {
            query_string = false
            cookies {
              forward = "none"
            }
        }

        viewer_protocol_policy = "redirect-to-https"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }

    restrictions {
      geo_restriction {
          restriction_type = "whitelist"
          locations = [ "JP" ]
      }
    }
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}

resource "aws_cloudfront_origin_access_control" "documents" {
  name                              = "cf-documents"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_wafv2_web_acl" "documents" {
  provider    = aws.as_global
  name        = "waf-documents"
  scope       = "CLOUDFRONT"
  default_action {
    block {}
  }

  rule {
    name     = "allow_ips_in_ip_set"
    priority = 1
    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.local.arn
      }
    }

    visibility_config {
      sampled_requests_enabled   = false
      cloudwatch_metrics_enabled = false
      metric_name                = "WAF-IP-Rule"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    sampled_requests_enabled   = false
    metric_name                = "WAF"
  }
}

resource "aws_wafv2_ip_set" "local" {
  provider           = aws.as_global
  name               = "local-ip"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = ["0.0.0.0/0"]  # set acceptable IPAddress
}
