# Run with the mock API: python3 ../../mock-api/mock_tag_api.py & terraform init && terraform test
variables {
  validation_api_url = "http://127.0.0.1:18080"
}

run "valid_tags_plan_cleanly" {
  command = plan

  variables {
    tags = {
      ApplicationID    = "APM0001234"
      ApplicationOwner = "Jane.Doe@example.com"
      BusinessOwner    = "raj.k@example.com"
      CostCenter       = "CC10001"
      WBSCode          = "P-100234.01"
      extra            = { Environment = "prod" }
    }
  }

  assert {
    condition     = output.tags["Environment"] == "prod" && output.tags["CostCenter"] == "CC10001"
    error_message = "Validated tag map should merge extras with the mandatory tags."
  }
}

run "invalid_values_fail_the_plan" {
  command = plan

  variables {
    tags = {
      ApplicationID    = "APM0001234"
      ApplicationOwner = "someone@example.com"
      BusinessOwner    = "raj.k@example.com"
      CostCenter       = "CC99999"
      WBSCode          = "P-100234.01"
    }
  }

  expect_failures = [data.http.tag_validation]
}

run "bad_application_id_format_fails_validation" {
  command = plan

  variables {
    tags = {
      ApplicationID    = "1234"
      ApplicationOwner = "a@example.com"
      BusinessOwner    = "b@example.com"
      CostCenter       = "CC10001"
      WBSCode          = "P-100234.01"
    }
  }

  expect_failures = [var.tags]
}
