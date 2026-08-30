# ABOUTME: GitHub branch ruleset as code. Authoritative Layer 1 server-side gate.
# ABOUTME: Edit 'repository' to match your repo name. Requires GITHUB_TOKEN with admin scope.

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

resource "github_repository_ruleset" "main_protection" {
  name        = "protect-main"
  repository  = "DevOpsDaysAtlanta_2026_Cluster_Destruction_Ignite"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    creation                = true
    update                  = true
    deletion                = true
    non_fast_forward        = true
    required_linear_history = true
    required_signatures     = true

    pull_request {
      required_approving_review_count   = 1
      require_code_owner_review         = true
      require_last_push_approval        = true
      dismiss_stale_reviews_on_push     = true
      required_review_thread_resolution = true
    }

    required_status_checks {
      strict_required_status_checks_policy = true
      required_check {
        context        = "security-scan / checkov"
        integration_id = 15368
      }
      required_check {
        context        = "security-scan / trivy-fs"
        integration_id = 15368
      }
      required_check {
        context        = "security-scan / gitleaks"
        integration_id = 15368
      }
      required_check {
        context        = "security-scan / kube-linter"
        integration_id = 15368
      }
      required_check {
        context        = "policy-check / kyverno"
        integration_id = 15368
      }
      required_check {
        context        = "pr-validation / title"
        integration_id = 15368
      }
    }

    merge_queue {
      check_response_timeout_minutes = 60
      grouping_strategy              = "ALLGREEN"
      max_entries_to_build           = 5
      merge_method                   = "SQUASH"
    }
  }
}
