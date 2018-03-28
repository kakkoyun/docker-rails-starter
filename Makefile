.PHONY: docker-release docker-build docker-push docker-test compile-assets database-setup

VERSION := $(strip $(shell [ -d .git ] && git describe --always --tags --dirty))
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%S%Z")
VCS_URL := $(shell [ -d .git ] && git config --get remote.origin.url)
VCS_REF := $(strip $(shell [ -d .git ] && git rev-parse --short HEAD))
VCS_REF_MSG := $(shell if [ "$(IS_TAG)" != "" ]; then git tag -l -n1 $(IS_TAG) | awk '{$$1 = ""; print $$0;}'; else git log --format='%s' -n 1 $(VCS_REF); fi)

compile-assets:
	RAILS_ENV=production bundle exec rake assets:precompile

database-setup:
	bundle exec rake db:create && \
	bundle exec rake db:migrate && \
	bundle exec rake db:seed

docker-build:
	docker build --build-arg BUILD_DATE="$(BUILD_DATE)" \
		--build-arg VERSION="$(VERSION)" \
		--build-arg VCS_URL="$(VCS_URL)" \
		--build-arg VCS_REF="$(VCS_REF)" \
		--build-arg VCS_REF_MSG="$(VCS_REF_MSG)" \
		--compress -t docker-rails-starter:latest .

docker-push:
	docker push kakkoyun/docker-rails-starter:latest

docker-release: docker-build docker-push

docker-test:
	docker-compose -f docker-compose.build.yml up
