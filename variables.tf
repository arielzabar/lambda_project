
variable "bucket_name" {
  description = "Creates a unique bucket name"
  type        = string
  default     = "test-bucket-ariellez"
}

variable "region" {
  description = "region"
  type        = string
  default     = "us-east-1"
}

variable "lambda_role_name" {
  description = "lambda_role_name"
  type        = string
  default     = "lambda-role"
}

variable "lambda_function_name" {
  description = "lambda_function_name"
  type        = string
  default     = "lambda-function"
}

variable "runtime" {
  description = "runtime"
  type        = string
  default     = "python3.8"
}

variable "custom_lambda_env_vars" {
  description = "custom_lambda_env_vars"
  type = map(string)
  default     = {
    VT_API            = "ce9a6305e9979261dfca684a627c9d05d5890e838c2894d2cefb87e221374dc9"
  }
}
