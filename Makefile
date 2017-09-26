SHELL = /bin/bash
UID = $(shell id -u)

SWAGGER_AGGREGATOR_IMAGE    ?= docker.onedata.org/swagger-aggregator:1.5.0
SWAGGER_CLI_IMAGE           ?= docker.onedata.org/swagger-cli:1.5.0
SWAGGER_BOOTPRINT_IMAGE     ?= docker.onedata.org/swagger-bootprint:1.5.0
SWAGGER_MARKDOWN_IMAGE      ?= docker.onedata.org/swagger-gitbook:1.4.1
SWAGGER_COWBOY_SERVER_IMAGE ?= docker.onedata.org/swagger-codegen:2.3.0-cowboy
SWAGGER_PYTHON_CLIENT_IMAGE ?= docker.onedata.org/swagger-codegen:2.2.2-1b1767e
SWAGGER_JS_CLIENT_IMAGE     ?= docker.onedata.org/swagger-codegen:VFS-3144
SWAGGER_BASH_CLIENT_IMAGE   ?= docker.onedata.org/swagger-codegen:ID-2fc8126ac8
SWAGGER_REDOC_IMAGE         ?= docker.onedata.org/swagger-redoc:1.0.0

BRANCH = $(shell git rev-parse --abbrev-ref HEAD)

.PHONY : all swagger.json
all : cowboy-server python-client bash-client doc-static doc-markdown

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
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger -t ${SWAGGER_COWBOY_SERVER_IMAGE} generate -i ./swagger.json -l cowboy -o ./generated/cowboy
	./fix_generated.py

python-client: validate
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger -t ${SWAGGER_PYTHON_CLIENT_IMAGE} generate -i ./swagger.json -l python -o ./generated/python -c python-config.json

bash-client: validate
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger -t ${SWAGGER_BASH_CLIENT_IMAGE} generate -i ./swagger.json -l bash -o ./generated/bash -c bash-config.json

javascript-client: validate
	docker run --rm -e "CHOWNUID=${UID}" -v `pwd`:/swagger -t ${SWAGGER_JS_CLIENT_IMAGE}  generate -i ./swagger.json -l javascript -o ./generated/javascript/ -c ./javascript-config.json

javascript-update-repo: javascript-client
	rm -rf generated/javascript-git
	git clone ssh://git@git.plgrid.pl:7999/vfs/onepanel-javascript-client.git generated/javascript-git
	# Commit&push the changes to the client repository
	cd generated/javascript-git && \
	git checkout ${BRANCH} && \
	cp -R ../javascript . && \
    git add -A . && \
    git config user.email "bamboo@onedata.org" && \
    git config user.name "Bamboo Agent" && \
    git commit -a -m "Auto update" && \
    git push origin ${BRANCH} && \
    cd ../.. && \
    rm -rf generated/javascript-git

doc-static: validate
	docker run --rm -e CHOWNUID=${UID} -v `pwd`:/swagger -t ${SWAGGER_BOOTPRINT_IMAGE} swagger ./swagger.json generated/static

	@sed -n '/<body>/,/<\/body>/p' generated/static/index.html | sed -e '1s/.*<body>//' -e '$s/<\/body>.*//' -e 's/\/definitions\//definitions--/g' -e 's/<div class=\"container\"/<div class=\"container swagger\"/' > generated/static/oneprovider-static.html

doc-markdown: validate
	docker run --rm -v `pwd`:/swagger -t ${SWAGGER_MARKDOWN_IMAGE} convert -i ./swagger.json -d ./generated/gitbook -c ./gitbook.properties

preview: validate
	$(info Open http://localhost:8088  (or http://$${DOCKER_MACHINE_IP}:8088))
	@docker run -v `pwd`/swagger.json:/usr/share/nginx/html/swagger.json:ro -p 8088:80 ${SWAGGER_REDOC_IMAGE}

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
	done
	@git checkout master
