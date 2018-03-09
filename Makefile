SHELL = /bin/bash

PYTHON_DIR = .venv
NODE_DIR = node_modules
SUBMODULE_DIR = tileserver-gl
MAKO_CMD = ${PYTHON_DIR}/bin/mako-render
PIP_CMD = ${PYTHON_DIR}/bin/pip


.PHONY: help
help:
	@echo ""
	@echo "- user                 Install the project"
	@echo "- dockerbuild          Builds all images via docker-compose"
	@echo "- dockerrun            Launches all the containers for the service"
	@echo "- dockerpurge          Remove all docker related docker containers and images"
	@echo "- rancherdeploydev     Deploys the app to Rancher"
	@echo "- clean                Remove generated templates"
	@echo "- cleanall             Remove all build artefacts"
	@echo ""

.PHONY: user
user: ${PYTHON_DIR}/requirements.timestamp ${NODE_DIR}/package.timestamp

.PHONY: dockerbuild
dockerbuild:
	export RANCHER_DEPLOY=false && make docker-compose.yml && docker-compose build

.PHONY: dockerrun
dockerrun:
	export RANCHER_DEPLOY=false && make docker-compose.yml && docker-compose up -d

.PHONY: rancherdeploydev
rancherdeploydev: guard-RANCHER_ACCESS_KEY \
                  guard-RANCHER_SECRET_KEY \
                  guard-RANCHER_URL
	export RANCHER_DEPLOY=true && make docker-compose.yml
	$(call start_service,$(RANCHER_ACCESS_KEY),$(RANCHER_SECRET_KEY),$(RANCHER_URL),dev)

.PHONY: dockerpurge
dockerpurge:
	@if test "$(shell sudo docker ps -a -q --filter name=servicetileservergl)" != ""; then \
		sudo docker rm -f $(shell sudo docker ps -a -q --filter name=servicetileservergl); \
	fi
	@if test "$(shell sudo docker images -q swisstopo/tileserver-gl)" != ""; then \
		sudo docker rmi -f swisstopo/tileserver-gl; \
	fi
	@if test "$(shell sudo docker images -q swisstopo/nginx-tileserver-gl)" != ""; then \
		sudo docker rmi -f swisstopo/nginx-tileserver-gl; \
	fi

${PYTHON_DIR}:
	virtualenv ${PYTHON_DIR}

${PYTHON_DIR}/requirements.timestamp: ${PYTHON_DIR} requirements.txt
	${PIP_CMD} install -r requirements.txt
	touch $@

${NODE_DIR}/package.timestamp: package.json
	npm install
	touch $@

docker-compose.yml::
	${MAKO_CMD} --var "rancher_deploy=$(RANCHER_DEPLOY)" docker-compose.yml.in > $@

define start_service
	rancher --access-key $1 --secret-key $2 --url $3 rm --stop --type stack service-tileservergl-$4 || echo "Nothing to remove"
	rancher --access-key $1 --secret-key $2 --url $3 up --stack service-tileservergl-$4 --pull --force-upgrade --confirm-upgrade -d
endef

guard-%:
	@ if test "${${*}}" = ""; then \
	  echo "Environment variable $* not set. Add it to your command."; \
	  exit 1; \
	fi

.PHONY: clean
clean:
	rm -f docker-compose.yml

.PHONY: cleanall
cleanall: clean
	rm -rf ${PYTHON_DIR}
	rm -rf ${NODE_DIR}
