provider "aws" {
  region = "us-east-1"
}

locals {
  content_types = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
  }
  s3_origin_id = "myS3Origin"
}
resource "aws_s3_bucket" "subdomain" {
  bucket = "marcellusb.com"
}
resource "aws_s3_bucket_website_configuration" "subdomainconfig" {
  bucket = aws_s3_bucket.subdomain.id

  index_document {
    suffix = "ITSupportSpecialistResumeMarcellusBryan.html"
  }

  error_document {
    key = "404NOTFOUND.html"
  }
}

resource "aws_s3_bucket_versioning" "subdomainv" {
  bucket = aws_s3_bucket.subdomain.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_ownership_controls" "subdomaincontrols" {
  bucket = aws_s3_bucket.subdomain.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "subdomainaccess" {
  bucket = aws_s3_bucket.subdomain.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "subdomainacl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.subdomaincontrols,
    aws_s3_bucket_public_access_block.subdomainaccess,
  ]

  bucket = aws_s3_bucket.subdomain.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.subdomain.id
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "PublicReadGetObject",
          "Effect" : "Allow",
          "Principal" : "*",
          "Action" : "s3:GetObject",
          "Resource" : "arn:aws:s3:::${aws_s3_bucket.subdomain.id}/*"
        }
      ]
    }
  )
}
resource "aws_s3_object" "ITSupportSpecialistResumeMarcellusBryan" {
  bucket = aws_s3_bucket.subdomain.id
  key    = "ITSupportSpecialistResumeMarcellusBryan.html"
  source = "/Users/marcellusbryan/.aws/TerraformConfigurations/ResumeProject/Resumewebsite/ITSupportSpecialistResumeMarcellusBryan.html"
  content_type = "text/html"
  content_disposition = "inline"
  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("/Users/marcellusbryan/.aws/TerraformConfigurations/ResumeProject/Resumewebsite/ITSupportSpecialistResumeMarcellusBryan.html")
}
resource "aws_s3_object" "styles" {
  bucket = aws_s3_bucket.subdomain.id
  key    = "styles.css"
  source = "/Users/marcellusbryan/.aws/TerraformConfigurations/ResumeProject/Resumewebsite/styles.css"
  content_type = "text/css"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("/Users/marcellusbryan/.aws/TerraformConfigurations/ResumeProject/Resumewebsite/styles.css")
}
resource "aws_s3_object" "NOTFOUND" {
  bucket = aws_s3_bucket.subdomain.id
  key    = "404NOTFOUND.txt"
  source = "/Users/marcellusbryan/.aws/TerraformConfigurations/ResumeProject/Resumewebsite/404NOTFOUND.txt"
  content_type = "text/html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("/Users/marcellusbryan/.aws/TerraformConfigurations/ResumeProject/Resumewebsite/404NOTFOUND.txt")
}
resource "aws_cloudfront_distribution" "marcellusbdist" {
  origin {
    domain_name              = aws_s3_bucket.subdomain.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "ITSupportSpecialistResumeMarcellusBryan.html"

  aliases = ["marcellusb.com"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }
  tags = {
    Environment = "production"
  }

 viewer_certificate {
  acm_certificate_arn = "arn:aws:acm:us-east-1:752948194002:certificate/efa63c60-133b-4787-9e86-c46a1ca4328e"
  ssl_support_method  = "sni-only"
}

} 
resource "aws_dynamodb_table" "VisitorCount" {
  name           = "VisitorCount"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "Id"

  attribute {
    name = "Id"
    type = "S"
  }
  tags = {
    Name        = "dynamodb-table-1"
    Environment = "production"
  }
}

resource "aws_api_gateway_rest_api" "ResumeWebsiteAPI" {
  name        = "ResumeWebsiteAPI"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  api_key_source              = "HEADER"
  disable_execute_api_endpoint = false
}

resource "aws_api_gateway_resource" "MyResource" {
  rest_api_id = aws_api_gateway_rest_api.ResumeWebsiteAPI.id
  parent_id   = aws_api_gateway_rest_api.ResumeWebsiteAPI.root_resource_id
  path_part   = "root"
}
resource "aws_api_gateway_method" "POST" {
  rest_api_id   = aws_api_gateway_rest_api.ResumeWebsiteAPI.id
  resource_id   = aws_api_gateway_resource.MyResource.id
  http_method   = "POST"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "POST" {
  rest_api_id             = aws_api_gateway_rest_api.ResumeWebsiteAPI.id
  resource_id             = aws_api_gateway_resource.MyResource.id
  http_method             = aws_api_gateway_method.POST.http_method
  integration_http_method = "POST"
  uri                     = aws_lambda_function.update_visitor_count.invoke_arn
  type                    = "AWS"
  timeout_milliseconds    = 29000
}
resource "aws_api_gateway_method_response" "POSTR" {
  rest_api_id = aws_api_gateway_rest_api.ResumeWebsiteAPI.id
  resource_id = aws_api_gateway_resource.MyResource.id
  http_method = aws_api_gateway_method.POST.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}
resource "aws_api_gateway_integration_response" "intergrationresponse" {
  rest_api_id = aws_api_gateway_rest_api.ResumeWebsiteAPI.id
  resource_id = aws_api_gateway_resource.MyResource.id
  http_method = aws_api_gateway_method.POST.http_method
  status_code = aws_api_gateway_method_response.POSTR.status_code

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'https://marcellusb.com'"
  }
}
resource "aws_iam_role" "role" {
  assume_role_policy    = jsonencode(
      {
          Statement = [
              {
                  Action    = "sts:AssumeRole"
                  Effect    = "Allow"
                  Principal = {
                      Service = "lambda.amazonaws.com"
                  }
              },
          ]
          Version   = "2012-10-17"
      }
  )
  force_detach_policies = false
  managed_policy_arns   = [
      "arn:aws:iam::752948194002:policy/service-role/AWSLambdaBasicExecutionRole-7268408c-91a2-4c37-bc80-4296821368bc",
      "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
      "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole",
      "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs",
      ""
  ]
  max_session_duration  = 3600
  name                  = "UpdateVistorCount-role-mwphsozi"
  path                  = "/service-role/"
  tags                  = {}
  tags_all              = {}
}
resource "aws_api_gateway_method" "OPTIONSm" {
  rest_api_id   = aws_api_gateway_rest_api.ResumeWebsiteAPI.id
  resource_id   = aws_api_gateway_resource.MyResource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
  api_key_required = false
  
}
resource "aws_api_gateway_method_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.ResumeWebsiteAPI.id
  resource_id = aws_api_gateway_resource.MyResource.id
  http_method = aws_api_gateway_method.OPTIONSm.http_method
  status_code = 200

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}
resource "aws_api_gateway_integration" "options" {
  rest_api_id             = aws_api_gateway_rest_api.ResumeWebsiteAPI.id
  resource_id             = aws_api_gateway_resource.MyResource.id
  http_method             = aws_api_gateway_method.OPTIONSm.http_method
  type                    = "MOCK"
    request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
  

}
resource "aws_api_gateway_integration_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.ResumeWebsiteAPI.id
  resource_id = aws_api_gateway_resource.MyResource.id
  http_method = aws_api_gateway_method.OPTIONSm.http_method
  status_code = 200
    response_templates = {
    "application/json" = <<EOT
{
  "statusCode": 200,
}
EOT
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'https://marcellusb.com'"
  }
}

resource "aws_lambda_function" "update_visitor_count" {
  function_name = "UpdateVistorCount"
  role          = "arn:aws:iam::752948194002:role/service-role/UpdateVistorCount-role-mwphsozi"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  memory_size   = 128
  timeout       = 3
  filename      = "/Users/marcellusbryan/.aws/TerraformConfigurations/ResumeProject/UpdateVistorCount/lambda_function4.zip"

  tracing_config {
    mode = "PassThrough"
  }
  architectures = [
    "x86_64"
  ]
  environment {
    variables = {}
  }
   ephemeral_storage {
        size = 512
    }
}
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_visitor_count.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:us-east-1:752948194002:o9wgtsaoaf/*/POST/root"
}




