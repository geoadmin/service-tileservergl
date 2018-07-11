SHELL = /bin/bash

CI ?= false
RANCHER_DEPLOY ?= false
IMAGE_TAG ?= staging
STAGING ?= dev

CURRENT_DIR = $(shell pwd)
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
	@echo "- dockerpushstaging    Push locally builded 'staging' images to dockerhub"
	@echo "- rancherdeploydev     Deploys the app to Rancher"
	@echo "- clean                Remove generated templates"
	@echo "- cleanall             Remove all build artefacts"
	@echo ""

.PHONY: user
user: ${PYTHON_DIR}/requirements.timestamp ${NODE_DIR}/package.timestamp

.PHONY: dockerbuild
dockerbuild:
	export RANCHER_DEPLOY=false && make docker-compose.yml && docker-compose build

.PHONY: dockerbuildprod
dockerbuildprod:
	export STAGING=prod && export IMAGE_TAG=production && make dockerbuild
	
.PHONY: dockerbuildint
dockerbuildint:
	export STAGING=int && export IMAGE_TAG=integration && make dockerbuild

.PHONY: dockerbuilddev
dockerbuilddev:
	export STAGING=dev && export IMAGE_TAG=staging && make dockerbuild

.PHONY: dockerrun
dockerrun:
	export RANCHER_DEPLOY=false && make docker-compose.yml && docker-compose up -d

.PHONY: dockerrunprod
dockerrunprod:
	export STAGING=prod && export IMAGE_TAG=production && make dockerrun

.PHONY: dockerrunint
dockerrunint:
	export STAGING=int && export IMAGE_TAG=staging && make dockerrun

.PHONY: dockerrundev
dockerrundev:
	export STAGING=dev && export IMAGE_TAG=staging && make dockerrun

.PHONY: rancherdeploydev
rancherdeploydev: guard-RANCHER_ACCESS_KEY_DEV \
                  guard-RANCHER_SECRET_KEY_DEV \
                  guard-RANCHER_URL_DEV
	export RANCHER_DEPLOY=true && export STAGING=dev && export IMAGE_TAG=staging && make docker-compose.yml
	$(call start_service,$(RANCHER_ACCESS_KEY_DEV),$(RANCHER_SECRET_KEY_DEV),$(RANCHER_URL_DEV),dev)

.PHONY: rancherdeployprod
rancherdeployprod: guard-RANCHER_ACCESS_KEY_PROD \
		  guard-RANCHER_SECRET_KEY_PROD \
                  guard-RANCHER_URL_PROD
	export RANCHER_DEPLOY=true && export STAGING=prod && IMAGE_TAG=production && make docker-compose.yml
	$(call start_service,$(RANCHER_ACCESS_KEY_PROD),$(RANCHER_SECRET_KEY_PROD),$(RANCHER_URL_PROD),prod)

.PHONY: rancherdeployint
rancherdeployprod: guard-RANCHER_ACCESS_KEY_DEV \
                  guard-RANCHER_SECRET_KEY_DEV \
                  guard-RANCHER_URL_DEV
	export RANCHER_DEPLOY=true && export STAGING=int && IMAGE_TAG=integration && make docker-compose.yml
	$(call start_service,$(RANCHER_ACCESS_KEY_DEV),$(RANCHER_SECRET_KEY_DEV),$(RANCHER_URL_DEV),int)





.PHONY: dockerpurge
dockerpurge:
	@if test "$(shell docker ps -a -q --filter name=servicetileservergl)" != ""; then \
		sudo docker rm -f $(shell sudo docker ps -a -q --filter name=servicetileservergl); \
	fi
	@if test "$(shell docker images -q swisstopo/tileserver-gl)" != ""; then \
		sudo docker rmi -f swisstopo/tileserver-gl:staging; \
	fi
	@if test "$(shell docker images -q swisstopo/nginx-tileserver-gl)" != ""; then \
		sudo docker rmi -f swisstopo/nginx-tileserver-gl:staging; \
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
	source rc_user && ${MAKO_CMD} --var "rancher_deploy=${RANCHER_DEPLOY}" --var "ci=${CI}" --var "image_tag=${IMAGE_TAG}" --var staging=${STAGING} docker-compose.yml.in > $@

nginx/nginx.conf::
	source rc_user && ${MAKO_CMD} nginx/nginx.conf.in > $@

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

.PHONY: dockerpushstaging
dockerpushstaging:
	$(call docker_push,swisstopo/nginx-tileserver-gl:staging)
	$(call docker_push,swisstopo/tileserver-gl:staging)

.PHONY: dockerpushprod
dockerpushprod:
	$(call docker_push,swisstopo/nginx-tileserver-gl:production)
	$(call docker_push,swisstopo/tileserver-gl:production)




# push to dockerhub
define docker_push
        @if test "$(shell docker images $1 | grep `echo $1 | awk -F ':' '{print $$2}'` )" != ""; then \
                docker push $1; \
        else \
                echo "there is no image called $1"; exit 1; \
        fi
endef

