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
	@echo "- rancherdeploydev     Deploys the app to Rancher"
	@echo "- clean                Remove generated templates"
	@echo "- cleanall             Remove all build artefacts"
	@echo ""

.PHONY: user
user:
	@if [ ! -d  ${PYTHON_DIR} ]; then virtualenv ${PYTHON_DIR}; fi
	@if [ ! -d  ${NODE_DIR} ]; then npm install; fi
	@if [ ! -d  ${SUBMODULE_DIR} ]; then git submodule init && git submodule update; fi
	${PIP_CMD} install Mako

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
	@if test "$(shell sudo docker ps -a -q)" != ""; then \
		sudo docker rm -f $(shell sudo docker ps -a -q); \
	else \
		echo "No container was found"; \
	fi
	@if test "$(shell sudo docker images -q)" != ""; then \
		sudo docker rmi -f $(shell sudo docker images -q); \
	else \
		echo "No image was found"; \
	fi

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
