resource "mysql_database" "goipsms" {
  name = "goipsms"
}

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "random_string" "username" {
  length  = 16
  special = false
}

resource "mysql_user" "goipsms" {
  user               = random_string.username.result
  host               = "%"
  plaintext_password = random_password.password.result
}

resource "mysql_grant" "goipsms" {
  user       = mysql_user.goipsms.user
  host       = mysql_user.goipsms.host
  database   = mysql_database.goipsms.name
  privileges = ["ALL"]
}

resource "vault_kv_secret_v2" "goipsms" {
  mount = "api_providers"
  name  = "goipsms"
  data_json = jsonencode({
    username = random_string.username.result
    password = random_password.password.result
  })
}
