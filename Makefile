REPOSITORY := artemstepanenko
NAME := bulletins
VERSION := $(shell grep '^version = ' build.gradle.kts | sed 's/version = "\(.*\)"/\1/' | sed 's/-SNAPSHOT//')

test:
	./gradlew test

start: run

run:
	./gradlew bootRun

update-gradle:
	./gradlew wrapper --gradle-version 9.2.1

update-deps:
	./gradlew refreshVersions

install:
	./gradlew dependencies

build:
	./gradlew build

lint:
	./gradlew spotlessCheck

lint-fix:
	./gradlew spotlessApply

image:
	docker build -t $(REPOSITORY)/$(NAME):$(VERSION) .

container:
	docker run --rm -p 8080:8080 $(REPOSITORY)/$(NAME):$(VERSION)

publish:
	docker push $(REPOSITORY)/$(NAME):$(VERSION)

setup:
	ansible-galaxy role install -r requirements.yml && ansible-galaxy collection install -r requirements.yml

deploy:
	ansible-playbook playbook.yml -i inventory.ini

.PHONY: build image container publish deploy setup
