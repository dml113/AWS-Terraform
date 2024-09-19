# CloudFront OAC 생성
resource "aws_cloudfront_origin_access_control" "example" {
  name            = "example-oac"
  description     = "OAC for S3 access"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

# S3 버킷 정책
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.my_bucket.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

# CloudFront Function 생성
resource "aws_cloudfront_function" "wsi_static_function" {
  name    = "wsi-static-function"
  runtime = "cloudfront-js-2.0"
  code    = <<EOF
function handler(event) {
    var request = event.request;
    var uri = request.uri;

    if (uri === '/index.html' || uri.startsWith('/images')) {
        return request;
    }

    return {
        statusCode: 302,
        statusDescription: 'Found',
        headers: {
            'location': { 'value': '/index.html' }
        }
    };
}
EOF

  publish = true
}

# CachingDisabled Cache Policy 생성
resource "aws_cloudfront_cache_policy" "caching_disabled" {
  name            = "NoCachePolicy"
  default_ttl     = 0
  max_ttl         = 0
  min_ttl         = 0
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# CloudFront 배포 생성
resource "aws_cloudfront_distribution" "my_distribution" {
  origin {
    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.my_bucket.id

    origin_access_control_id = aws_cloudfront_origin_access_control.example.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for my S3 bucket"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.my_bucket.id

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    cache_policy_id = aws_cloudfront_cache_policy.caching_disabled.id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.wsi_static_function.arn
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/images/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.my_bucket.id

    forwarded_values {
      query_string = true
      query_string_cache_keys = ["height", "width"]
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.wsi_static_function.arn
    }
  }

  

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}