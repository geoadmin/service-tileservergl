SHELL = /bin/bash

INSTALL_DIR = .venv
MAKO_CMD = ${INSTALL_DIR}/bin/mako-render
PIP_CMD = ${INSTALL_DIR}/bin/pip


.PHONY: user
user:
	@if [ ! -d  ${INSTALL_DIR} ]; then virtualenv ${INSTALL_DIR} && git submodule init && git submodule update; fi
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
	rm -rf ${INSTALL_DIR}
