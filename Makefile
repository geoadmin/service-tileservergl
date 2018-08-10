include ./lib-makefiles/docker.mk
SHELL:=/bin/bash
NODE_DIR = node_modules
VENV = .venv
MAKO_CMD:=${VENV}/bin/mako-render
PROJECT_NAME:=tileserver-gl
PIP_CMD = ${VENV}/bin/pip

.PHONY: help
help:
	@echo ""
	@echo "- user					install the project"
	@echo "- docker-build-[dev|int|prod|tiles]	Build all the images via docker compose"
	@echo "- docker-run-[dev|int|prod]		Launches all the containers for the service"
	@echo "- docker-purge				Remove all docker related docker containers and images"
	@echo "- docker-push-[dev|int|prod|tiles]	Push locally builded images to dockerhub"
	@echo "- docker-pipe-[dev|int|prod|tiles]	Purge, build the images, retag them with the date and push that image to dockerhub"
	@echo "- clean					Remove generated templates"
	@echo "- cleanall				Remove all build artefacts"
	@echo ""

${VENV}:
	virtualenv ${VENV}

${VENV}/requirements.timestamp: ${VENV} requirements.txt
	${PIP_CMD} install -r requirements.txt
	touch $@

${NODE_DIR}/package.timestamp: package.json
	npm install
	touch $@

docker-build-%:
	source rc_user && $(call dockerbuild,${MAKO_CMD},${PROJECT_NAME},$*,--var "ci=false")

docker-run-%:
	source rc_user && $(call dockerrun,${MAKO_CMD},${PROJECT_NAME},$*,--var "ci=false")

docker-purge:
	$(call dockerpurge,${PROJECT_NAME})

docker-push-%:
	$(call dockerpush,$*,${PROJECT_NAME})

docker-pipe-%:
	source rc_user && $(call dockerpipe,${MAKO_CMD},${PROJECT_NAME},$*,--var "ci=false")

.PHONY: user
user: ${VENV}/requirements.timestamp ${NODE_DIR}/package.timestamp

.PHONY: clean
clean:
	$(call docker-clean)
.PHONY: cleanall
cleanall: clean
	sudo rm -rf ${VENV}
	sudo rm -rf ${NODE_DIR}
