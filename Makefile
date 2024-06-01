-include .env

test-governance:
	@echo "testing governance"
	@forge test --match-contract GovernanceTest

