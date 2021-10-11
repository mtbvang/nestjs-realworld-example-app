# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE REMOTE STATE STORAGE
# ---------------------------------------------------------------------------------------------------------------------

terraform {

  # Only allow this Terraform version. Note that if you upgrade to a newer version, Terraform won't allow you to use an
  # older version, so when you upgrade, you should upgrade everyone on your team and your CI servers all at once.
  required_version = "= 0.12.17"

  required_providers {
    heroku = {
      source  = "heroku/heroku"
      version = "~> 4.0"
    }
  }
}

### API

resource "heroku_app" "api" {
  name   = "${var.heroku_team_name}-api-"
  region = var.region
  acm    = true

  organization = {
    name = "${var.heroku_team_name}"
  }
}

resource "heroku_addon" "papertrail_web_ui" {
  app  = "${heroku_app.api.id}"
  plan = "papertrail:choklad"
}

resource "heroku_app_release" "api" {
  app     = "${heroku_app.api.id}"
  slug_id = "${var.api_slug_id}"
}

resource "heroku_formation" "api" {
  app        = "${heroku_app.api.id}"
  type       = "web"
  quantity   = 1
  size       = "standard-1x"
  depends_on = ["heroku_app_release.api"]
}



