variable "env_name" {
  description = "The name of the environment to deploy to"
  type        = string
}

variable "region" {
  description = "The name of the region to deploy to"
  type        = string
}

variable "heroku_team_name" {
  description = "Name of the Heroku Team owning this complete deployment."
  type        = "string"
}

variable "api_slug_id" {
  description = "Heroku slug ID for API app"
  type        = "string"
}



