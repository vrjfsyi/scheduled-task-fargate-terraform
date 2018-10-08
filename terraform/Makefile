
.DEFAULT_GOAL := help

# copy from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html and edit it
.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: init
init: ## terraform init
	@terraform init

.PHONY: plan
plan: ## terraform plan
	@terraform plan

.PHONY: apply
apply: ## terraform apply
	@terraform apply

.PHONY: fmt
fmt: ## terraform fmt
	@terraform fmt

.PHONY: validate
validate: ## terraform validate
	@terraform validate

.PHONY: show
show: ## terraform show
	@terraform show

.PHONY: check_if_fmt_applied
check_if_fmt_applied: ## terraform fmt -check=true -diff=true
	@terraform fmt -check=true -diff=true

.PHONY: check_if_syntax_validated
check_if_syntax_validated: ## terraform validate -check-variables=false
	@terraform validate -check-variables=false