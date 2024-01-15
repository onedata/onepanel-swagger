SHELL = /bin/bash
UID = $(shell id -u)

SWAGGER_AGGREGATOR_IMAGE    ?= docker.onedata.org/swagger-aggregator:1.5.0
SWAGGER_CLI_IMAGE           ?= docker.onedata.org/swagger-cli:1.5.0
SWAGGER_BOOTPRINT_IMAGE     ?= docker.onedata.org/swagger-bootprint:1.5.0
SWAGGER_MARKDOWN_IMAGE      ?= docker.onedata.org/swagger-gitbook:1.4.1
SWAGGER_COWBOY_SERVER_IMAGE ?= docker.onedata.org/swagger-codegen:2.3.1-cowboy
SWAGGER_JS_CLIENT_IMAGE     ?= docker.onedata.org/swagger-codegen:VFS-3144
SWAGGER_BASH_CLIENT_IMAGE   ?= docker.onedata.org/swagger-codegen:VFS-6328
# Updated/newer docker images for swagger codegen v2 and v3
SWAGGER_PYTHON_CLIENT_IMAGE ?= swaggerapi/swagger-codegen-cli:2.4.20
SWAGGER_OPENAPI_CLIENT_IMAGE ?= swaggerapi/swagger-codegen-cli-v3:3.0.26

ifndef BRANCH
	# BRANCH should always be passed in case of git detached state. This is only a fallback.
	BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
endif

COMMIT_MESSAGE = $(shell git log -1 --pretty=format:%s)

.PHONY: all swagger.json
all: cowboy-server python-client bash-client doc-static doc-markdown

clean:
	@rm -rf generated packages swagger.json

swagger.json:
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger ${SWAGGER_AGGREGATOR_IMAGE}

validate: swagger.json
	@RESULT="$(shell docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger ${SWAGGER_CLI_IMAGE} validate /swagger/swagger.json 2>&1)"; \
	if [[ $$RESULT =~ .*SyntaxError.* ]]; then\
		echo "$$RESULT";\
		exit 1;\
	else\
		echo "swagger.json is valid.";\
	fi

cowboy-server: validate
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger -t ${SWAGGER_COWBOY_SERVER_IMAGE} generate -i ./swagger.json -l cowboy -o ./generated/cowboy -DapiFileNameSuffix="_rest_routes"
	./fix_generated.py

python-client: validate
	docker run --rm --user ${UID} -v `pwd`:/local -t ${SWAGGER_PYTHON_CLIENT_IMAGE} generate -i /local/swagger.json -l python -o /local/generated/python -c /local/python-config.json

# Generate OpenAPI v3 stubs 
python-client-openapi3:
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/local -t ${SWAGGER_OPENAPI_CLIENT_IMAGE} generate -i /local/openapi.json -l python -o /local/generated/python3 -c /local/python-config.json

# Convert Swagger v2 to OpenAPI v3
convert-swagger-v2tov3:
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/local -t ${SWAGGER_OPENAPI_CLIENT_IMAGE} generate -i /local/swagger.json -l openapi -o /local/

bash-client: validate
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger -t ${SWAGGER_BASH_CLIENT_IMAGE} generate -i ./swagger.json -l bash -o ./generated/bash -c bash-config.json

javascript-client: validate
	docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger -t ${SWAGGER_JS_CLIENT_IMAGE}  generate -i ./swagger.json -l javascript -o ./generated/javascript/ -c ./javascript-config.json
	./semversionize_js_package.py ./generated/javascript/package.json

javascript-update-repo: clean javascript-client
	if [ "${BRANCH}" = "HEAD" ]; then exit 1; fi
	rm -rf generated/javascript-git
	git clone ssh://git@git.onedata.org:7999/vfs/onepanel-javascript-client.git generated/javascript-git && \
	cd generated/javascript-git && \
	( ( git checkout ${BRANCH} && ( git pull || exit 1 ) ) || git checkout -b ${BRANCH} ) && \
	git rm -r * && \
	cp -R ../javascript/* . && \
	git add -A . && \
	git config user.email "bamboo@onedata.org" && \
	git config user.name "Bamboo Agent" && \
	( ( git status --porcelain && git commit -a -m "Auto update: ${COMMIT_MESSAGE}" ) || echo "nothing to commit" ) && \
	git push -u origin ${BRANCH} && \
	cd ../.. && \
	rm -rf generated/javascript-git

doc-static: validate
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger -t ${SWAGGER_BOOTPRINT_IMAGE} swagger ./swagger.json generated/static
	@sed -n '/<body>/,/<\/body>/p' generated/static/index.html | sed -e '1s/.*<body>//' -e '$s/<\/body>.*//' -e 's/\/definitions\//definitions--/g' -e 's/<div class=\"container\"/<div class=\"container swagger\"/' > generated/static/oneprovider-static.html

doc-markdown: validate
	docker run --rm -v `pwd`:/swagger -t ${SWAGGER_MARKDOWN_IMAGE} convert -i ./swagger.json -d ./generated/gitbook -c ./gitbook.properties

preview: validate
	./bamboos/scripts/build-redoc.sh preview

bash-packages: RELEASES = $(shell git branch -a | grep "release/" | sed -n 's/.*release\/\(.*\)/\1/p')
bash-packages:
	@git checkout master
	@releases=(${RELEASES});\
	for release_branch in $${releases[@]}; do\
		echo "#################################################";\
		echo " Building Bash client release: $$release_branch";\
		echo "#################################################";\
		git checkout release/$$release_branch;\
		rm -rf generated;\
		docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger -t ${SWAGGER_AGGREGATOR_IMAGE};\
		docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger -t ${SWAGGER_BASH_CLIENT_IMAGE} generate -i ./swagger.json -l bash -o ./generated/bash -c bash-config.json;\
		mkdir -p "packages/bash/$$release_branch";\
		cp generated/bash/onepanel-rest-cli "packages/bash/$$release_branch/";\
		cp generated/bash/_onepanel-rest-cli "packages/bash/$$release_branch/";\
		cp generated/bash/onepanel-rest-cli.bash-completion "packages/bash/$$release_branch/";\
	done;\
    custom_releases=( develop );\
    for release_branch in $${custom_releases[@]}; do\
        echo "#################################################";\
        echo " Building Bash client release: $$release_branch";\
        echo "#################################################";\
        git checkout $$release_branch;\
        rm -rf generated;\
        docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger -t ${SWAGGER_AGGREGATOR_IMAGE};\
        docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger -t ${SWAGGER_BASH_CLIENT_IMAGE} generate -i ./swagger.json -l bash -o ./generated/bash -c bash-config.json;\
        mkdir -p "packages/bash/$$release_branch";\
        cp generated/bash/onepanel-rest-cli "packages/bash/$$release_branch/";\
        cp generated/bash/_onepanel-rest-cli "packages/bash/$$release_branch/";\
        cp generated/bash/onepanel-rest-cli.bash-completion "packages/bash/$$release_branch/";\
    done
	@git checkout master

submodules:
	git submodule sync --recursive ${submodule}
	git submodule update --init --recursive ${submodule}

codetag-tracker:
	./bamboos/scripts/codetag-tracker.sh --branch=${BRANCH} --excluded-dirs=
