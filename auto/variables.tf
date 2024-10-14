variable "o11y_cloud" {
  type = string({
    access_token      = "wSLOU3EIWLTOruPYkpymKw"
    realm             = "us1"
    lambda_layer      = "arn:aws:lambda:us-east-1:254067382080:layer:splunk-apm:108"
  })
  
  sensitive = true
  
  validation {
    condition = length(var.o11y_cloud.deploy_env_prefix) == 6
    error_message = "The deployment environment prefix must be 6 characters long!"
  }
}

variable "prefix" {
  type = string({
    value = "gfkono"
  })
}