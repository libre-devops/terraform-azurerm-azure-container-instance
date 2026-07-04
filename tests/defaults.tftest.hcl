# Tests for the module. azurerm is mocked (no credentials, no cloud):
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {}

variables {
  resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-001"
  location          = "uksouth"
  tags              = { Environment = "tst" }
}

# One group, one container: a public Linux group with a DNS label.
run "fast_to_get_going" {
  command = apply

  variables {
    container_groups = {
      "aci-ldo-uks-tst-001" = {
        dns_name_label = "aci-ldo-uks-tst-001"
        containers = [
          {
            name   = "nginx"
            image  = "nginx:1.27-alpine"
            cpu    = 0.5
            memory = 1.0
            ports  = [{ port = 80, protocol = "TCP" }]
          }
        ]
      }
    }
  }

  assert {
    condition     = azurerm_container_group.this["aci-ldo-uks-tst-001"].os_type == "Linux"
    error_message = "os_type should default to Linux."
  }

  assert {
    condition     = azurerm_container_group.this["aci-ldo-uks-tst-001"].ip_address_type == "Public"
    error_message = "ip_address_type should default to Public."
  }

  assert {
    condition     = azurerm_container_group.this["aci-ldo-uks-tst-001"].restart_policy == "Always"
    error_message = "restart_policy should default to Always."
  }
}

# Multiple containers, an init container, a probe, and an identity.
run "multi_container_with_init" {
  command = apply

  variables {
    container_groups = {
      "aci-ldo-uks-tst-002" = {
        identity = { type = "SystemAssigned" }
        init_containers = [
          { name = "setup", image = "busybox:1.36", commands = ["sh", "-c", "echo ready"] }
        ]
        containers = [
          {
            name   = "web"
            image  = "nginx:1.27-alpine"
            cpu    = 0.5
            memory = 1.0
            ports  = [{ port = 80 }]
            liveness_probe = {
              http_get       = { path = "/", port = 80, scheme = "http" }
              period_seconds = 15
            }
          },
          {
            name                         = "sidecar"
            image                        = "busybox:1.36"
            cpu                          = 0.25
            memory                       = 0.5
            commands                     = ["sh", "-c", "sleep 3600"]
            secure_environment_variables = { TOKEN = "secret" }
          }
        ]
      }
    }
  }

  assert {
    condition     = length(azurerm_container_group.this["aci-ldo-uks-tst-002"].container) == 2
    error_message = "Both containers should be configured."
  }

  assert {
    condition     = length(azurerm_container_group.this["aci-ldo-uks-tst-002"].init_container) == 1
    error_message = "The init container should be configured."
  }

  assert {
    condition     = azurerm_container_group.this["aci-ldo-uks-tst-002"].identity[0].type == "SystemAssigned"
    error_message = "The identity should be attached."
  }
}

run "rejects_private_without_subnet" {
  command = plan

  variables {
    container_groups = {
      "aci-ldo-uks-tst-003" = {
        ip_address_type = "Private"
        containers      = [{ name = "c", image = "nginx", cpu = 0.5, memory = 1.0 }]
      }
    }
  }

  expect_failures = [var.container_groups]
}

run "rejects_bad_os_type" {
  command = plan

  variables {
    container_groups = {
      "aci-ldo-uks-tst-004" = {
        os_type    = "Darwin"
        containers = [{ name = "c", image = "nginx", cpu = 0.5, memory = 1.0 }]
      }
    }
  }

  expect_failures = [var.container_groups]
}
