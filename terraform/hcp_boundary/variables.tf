variable "controller_url" {
  type = string
  # Add your controller URL here, 
  # You can find your controller once you've enabled Boundary at https://portal.cloud.hashicorp.com/
  # Note: cannot have a terminating '/' character
  # default = "https://4f699304-f8fc-4a51-bd92-36793c1526f3.boundary.hashicorp.cloud"
}

variable "auth_method_id" {
  type = string
  # Login to your Boundary environment and copy the "password" auth method ID that was created at deployment
  # Login -> Open Admin UI -> Auth methods -> "password"
  # default = "ampw_JDd4dKfPOE"
}

variable "bootstrap_user_login_name" {
  type = string
  # the username chosen of the user created when you enabled Boundary
  # default = "administrator"
}

variable "bootstrap_user_password" {
  type = string
  # the password chosen of the user created when you enabled Boundary
  # default = "correct-horse-battery-staple"
}

variable "target_ec2" {
  type = any
  # Add in IPs for any targets you would like to add
  # default = ["1.1.1.1", "2.2.2.2", "3.3.3.3"]
}

variable "target_db" {
  type = set(string)
  # Add in IPs for any targets you would like to add
  # default = ["products.cblnpwmljgks.us-east-1.rds.amazonaws.com"]
}
