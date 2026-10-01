# Workspace orchestrator (mfe-workspace) — fans out to sibling repos on mfe-net
#
#   make up               → full Docker mesh → http://localhost:8080
#   make assets-local-up  → local MinIO (:9000 / console :9001) — opt-in
#   make dev              → hybrid: backend infra + host apps + hybrid gateway
#   make down             → tear down all project containers (keeps mfe-net + volumes)
#
# Specs: plans/  | docs: docs/README.md

ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
NETWORK ?= mfe-net

BACKEND    := $(ROOT)/mfe-backend
SHELL_REPO := $(ROOT)/mfe-shell
GATEWAY    := $(ROOT)/mfe-gateway
LANDING    := $(ROOT)/mfe-landing
PRODUCT    := $(ROOT)/mfe-remote-product
ADMIN      := $(ROOT)/mfe-remote-admin
VUE        := $(ROOT)/mfe-remote-vue
FORMENGINE := $(ROOT)/mfe-remote-formengine

FE_REPOS := $(LANDING) $(PRODUCT) $(ADMIN) $(VUE) $(FORMENGINE)
ALL_REPOS := $(BACKEND) $(FE_REPOS) $(SHELL_REPO) $(GATEWAY)

.DEFAULT_GOAL := help

.PHONY: help ensure-network clean-network check-repos up down ps logs \
	dev bootstrap legacy-down assets-local-up assets-local-down

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage: make \033[36m<target>\033[0m\n\n"} \
		/^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@printf "\nMesh: \033[33mhttp://localhost:8080\033[0m\n\n"

check-repos: ## Abort if a sibling clone is missing
	@missing=""; \
	for d in $(ALL_REPOS); do \
	  [ -d "$$d" ] || missing="$$missing $$(basename $$d)"; \
	done; \
	if [ -n "$$missing" ]; then \
	  echo "✗ missing siblings:$$missing" >&2; \
	  echo "  Run: ./bootstrap.sh" >&2; \
	  exit 1; \
	fi

ensure-network: ## Create mfe-net if missing
	@docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK)
	@echo "✓ network $(NETWORK)"

clean-network: ## Remove mfe-net only if empty
	@ids=$$(docker network inspect $(NETWORK) -f '{{range .Containers}}{{.Name}} {{end}}' 2>/dev/null || true); \
	if [ -n "$$ids" ]; then \
	  echo "✗ $(NETWORK) still has containers: $$ids" >&2; \
	  exit 1; \
	fi; \
	docker network rm $(NETWORK) 2>/dev/null || true; \
	echo "✓ $(NETWORK) removed (or was absent)"

up: check-repos ensure-network ## Full Docker mesh → :8080
	@legacy=$$(docker ps -q --filter name=mfe-platform-); \
	if [ -n "$$legacy" ]; then \
	  echo "✗ legacy mfe-platform-* containers still running — run: make legacy-down" >&2; \
	  exit 1; \
	fi
	@echo "→ backend"
	@$(MAKE) -C $(BACKEND) up
	@echo "→ frontends (sequential — avoids make job-control races under parallel &)"
	@for d in $(FE_REPOS); do \
	  echo "  · $$(basename $$d)"; \
	  $(MAKE) -C $$d up || exit 1; \
	done
	@echo "→ shell"
	@$(MAKE) -C $(SHELL_REPO) up
	@echo "→ gateway"
	@$(MAKE) -C $(GATEWAY) up
	@echo ""
	@echo "✓ Mesh up → http://localhost:8080"
	@echo "  Assets: ASSETS_S3_* in mfe-backend/.env (R2), or: make assets-local-up"
	@echo "  Seeds: cd mfe-backend && make seed  (or RUN_SEEDS=true make -C mfe-backend up)"

assets-local-up: ensure-network ## Local MinIO + bucket seed (:9000 / console :9001)
	@$(MAKE) -C $(BACKEND) assets-up

assets-local-down: ## Stop local MinIO (leave the rest of the mesh)
	@$(MAKE) -C $(BACKEND) assets-down

down: ## Stop all sibling compose projects (keep network + volumes)
	-$(MAKE) -C $(GATEWAY) down
	-$(MAKE) -C $(SHELL_REPO) down
	@for d in $(FE_REPOS); do $(MAKE) -C $$d down || true; done
	-$(MAKE) -C $(BACKEND) down
	@echo "✓ down (mfe-net kept — make clean-network when empty)"

ps: ## Aggregate compose ps
	@for d in $(ALL_REPOS); do echo "── $$(basename $$d) ──"; $(MAKE) -C $$d ps || true; done

logs: ## Hint: use make -C <repo> logs
	@echo "Use: make -C mfe-backend logs | make -C mfe-shell logs | make -C mfe-gateway logs | …"

dev: check-repos ensure-network ## Hybrid: backend infra + hybrid gateway
	@$(MAKE) -C $(BACKEND) infra
	@$(MAKE) -C $(GATEWAY) gateway-dev
	@echo ""
	@echo "✓ Infra + hybrid gateway :8080"
	@echo "  Start apps in separate terminals:"
	@echo "    make -C mfe-backend          # or: cd mfe-backend && pnpm start:dev"
	@echo "    make -C mfe-shell dev"
	@echo "    make -C mfe-landing dev"
	@echo "    make -C mfe-remote-product dev"
	@echo "    make -C mfe-remote-admin dev"
	@echo "    make -C mfe-remote-vue dev"
	@echo "    make -C mfe-remote-formengine dev"
	@echo "  API: if not using backend container, run pnpm start:dev after make infra."

bootstrap: ## Clone siblings via ./bootstrap.sh
	@./bootstrap.sh