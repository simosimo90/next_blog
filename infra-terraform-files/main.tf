provider "aws" {

    region = "eu-central-1"
}

# Workflow steps :

# Write
# Init
# Plan
# Apply


# ***** List of Resources :

#S3 Bucket for website application

resource "aws_s3_bucket" "website" {
  bucket = "ttt-tf-blog-bucket"

  tags = {
    Name        = "ttt-tf-blog-bucket"
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
    bucket = "ttt-tf-blog-bucket"

    index_document {
      suffix = "index.html"
    }

    error_document {
      key = "index.html"
    }

}


# Add a policy to the S3 buccket

resource "aws_s3_bucket_policy" "my_user_get_object_policy" {
    bucket = aws_s3_bucket.website.id
    policy = data.aws_iam_policy_document.access_policy.json
}


# Create a policy document (json)

data "aws_iam_policy_document" "access_policy" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::125069145981:user/simon_t_admin"]
    }

    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.website.arn}/*",
    ]

  }

  statement {
    # Statement 2: Allow CloudFront OAI to get objects from the bucket
    effect = "Allow"
    principals {
      type        = "AWS"
      # This is how you reference the OAI's ARN in the policy
      identifiers = [aws_cloudfront_origin_access_identity.my_oai.iam_arn]
    }
    actions = ["s3:GetObject"]
    resources = [
      aws_s3_bucket.website.arn,        # Allows OAI to list/access the bucket itself (good practice for CloudFront)
      "${aws_s3_bucket.website.arn}/*", # Allows OAI to get objects from the bucket
    ]
  }
  
}


# CloudFront Origin Access Identity

resource "aws_cloudfront_origin_access_identity" "my_oai" {
  comment = "OAI for nextjs site"
}


# CloudFront Distribution

resource "aws_cloudfront_distribution" "s3_distribution" {

  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id = "S3-ttt-tf-blog-bucket"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.my_oai.cloudfront_access_identity_path
    }
  }
  
 enabled = true
 is_ipv6_enabled = true
 comment = "next.js portfolio site"
 default_root_object = "index.html"

 default_cache_behavior {
   allowed_methods = ["GET", "HEAD", "OPTIONS"]
   cached_methods = ["GET", "HEAD"]
   target_origin_id = "S3-ttt-tf-blog-bucket"

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

 viewer_certificate {
   cloudfront_default_certificate = true
 }

 restrictions {
   geo_restriction {
     restriction_type = "none"
   }
 }



}