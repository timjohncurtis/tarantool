#
# Travis CI rules
#

DOCKER_IMAGE?=packpack/packpack:debian-stretch
TEST_RUN_EXTRA_PARAMS?=
MAX_FILES?=65534
MAX_PROC?=2500

all: package

package:
	git clone https://github.com/packpack/packpack.git packpack
	./packpack/packpack

test: test_$(TRAVIS_OS_NAME)

# Redirect some targets via docker
test_linux: docker_test_debian
coverage: docker_coverage_debian
lto: docker_test_debian
lto_clang8: docker_test_debian_clang8
asan: docker_test_asan_debian

docker_%:
	mkdir -p ~/.cache/ccache
	docker run \
		--rm=true --tty=true \
		--volume "${PWD}:/tarantool" \
		--volume "${HOME}/.cache:/cache" \
		--workdir /tarantool \
		-e XDG_CACHE_HOME=/cache \
		-e CCACHE_DIR=/cache/ccache \
		-e COVERALLS_TOKEN=${COVERALLS_TOKEN} \
		-e TRAVIS_JOB_ID=${TRAVIS_JOB_ID} \
		-e CMAKE_EXTRA_PARAMS=${CMAKE_EXTRA_PARAMS} \
		-e APT_EXTRA_FLAGS="${APT_EXTRA_FLAGS}" \
		-e CC=${CC} \
		-e CXX=${CXX} \
		${DOCKER_IMAGE} \
		make -f .travis.mk $(subst docker_,,$@)

#########
# Linux #
#########

# Depends

# When dependencies in 'deps_debian' or 'deps_buster_clang_8' goal
# are changed, push a new docker image into GitLab Registry using
# the following command:
#
# $ make GITLAB_USER=foo -f .gitlab.mk docker_bootstrap
#
# It is highly recommended to only add dependencies (don't remove
# them), because all branches use the same latest image and it is
# often that a short-term branch is based on non-so-recent master
# commit, so the build requires old dependencies to be installed.
# See ce623a23416eb192ce70116fd14992e84e7ccbbe ('Enable GitLab CI
# testing') for more information.
deps_debian:
	apt-get update ${APT_EXTRA_FLAGS} && apt-get install -y -f \
		build-essential cmake coreutils sed \
		libreadline-dev libncurses5-dev libyaml-dev libssl-dev \
		libcurl4-openssl-dev libunwind-dev libicu-dev \
		python python-pip python-setuptools python-dev \
		python-msgpack python-yaml python-argparse python-six python-gevent \
		lcov ruby clang llvm llvm-dev zlib1g-dev autoconf automake libtool

deps_buster_clang_8: deps_debian
	echo "deb http://apt.llvm.org/buster/ llvm-toolchain-buster-8 main" > /etc/apt/sources.list.d/clang_8.list
	echo "deb-src http://apt.llvm.org/buster/ llvm-toolchain-buster-8 main" >> /etc/apt/sources.list.d/clang_8.list
	wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -
	apt-get update
	apt-get install -y clang-8 llvm-8-dev

# Release

build_debian:
	cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo -DENABLE_WERROR=ON ${CMAKE_EXTRA_PARAMS}
	make -j

test_debian_no_deps: build_debian
	cd test && /usr/bin/python test-run.py --force $(TEST_RUN_EXTRA_PARAMS)

test_debian: deps_debian test_debian_no_deps

test_debian_clang8: deps_debian deps_buster_clang_8 test_debian_no_deps

# Debug with coverage

build_coverage_debian:
	cmake . -DCMAKE_BUILD_TYPE=Debug -DENABLE_GCOV=ON
	make -j

test_coverage_debian_no_deps: build_coverage_debian
	# Enable --long tests for coverage
	cd test && /usr/bin/python test-run.py --force $(TEST_RUN_EXTRA_PARAMS) --long
	lcov --compat-libtool --directory src/ --capture --output-file coverage.info.tmp
	lcov --compat-libtool --remove coverage.info.tmp 'tests/*' 'third_party/*' '/usr/*' \
		--output-file coverage.info
	lcov --list coverage.info
	@if [ -n "$(COVERALLS_TOKEN)" ]; then \
		echo "Exporting code coverage information to coveralls.io"; \
		gem install coveralls-lcov; \
		echo coveralls-lcov --service-name travis-ci --service-job-id $(TRAVIS_JOB_ID) --repo-token [FILTERED] coverage.info; \
		coveralls-lcov --service-name travis-ci --service-job-id $(TRAVIS_JOB_ID) --repo-token $(COVERALLS_TOKEN) coverage.info; \
	fi;

coverage_debian: deps_debian test_coverage_debian_no_deps

# ASAN

build_asan_debian:
	CC=clang-8 CXX=clang++-8 cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DENABLE_WERROR=ON -DENABLE_ASAN=ON ${CMAKE_EXTRA_PARAMS}
	make -j

test_asan_debian_no_deps: build_asan_debian
	# Temporary excluded some tests by issue #4360:
	#  - To exclude tests from ASAN checks the asan/asan.supp file
	#    was set at the build time in cmake/profile.cmake file.
	#  - To exclude tests from LSAN checks the asan/lsan.supp file
	#    was set in environment options to be used at run time.
	cd test && ASAN=ON \
		LSAN_OPTIONS=suppressions=${PWD}/asan/lsan.supp \
		ASAN_OPTIONS=heap_profile=0:unmap_shadow_on_exit=1:detect_invalid_pointer_pairs=1:symbolize=1:detect_leaks=1:dump_instruction_bytes=1:print_suppressions=0 \
		./test-run.py --force $(TEST_RUN_EXTRA_PARAMS)

test_asan_debian: deps_debian deps_buster_clang_8 test_asan_debian_no_deps

#######
# OSX #
#######

# since Python 2 is EOL it's latest commit from tapped local formula is used
OSX_PKGS=openssl readline curl icu4c libiconv zlib autoconf automake libtool \
	cmake file://$${PWD}/tools/brew_taps/tntpython2.rb

deps_osx:
	# install brew using command from Homebrew repository instructions:
	#   https://github.com/Homebrew/install
	# NOTE: 'echo' command below is required since brew installation
	# script obliges the one to enter a newline for confirming the
	# installation via Ruby script.
	brew update || echo | /usr/bin/ruby -e \
		"$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	# try to install the packages either upgrade it to avoid of fails
	# if the package already exists with the previous version
	brew install --force ${OSX_PKGS} || brew upgrade ${OSX_PKGS}
	pip install --force-reinstall -r test-run/requirements.txt

build_osx:
	cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo -DENABLE_WERROR=ON ${CMAKE_EXTRA_PARAMS}
	make -j

test_osx_no_deps: build_osx
	# Limits: Increase the maximum number of open file descriptors on macOS:
	#   Travis-ci needs the "ulimit -n <value>" call
	#   Gitlab-ci needs the "launchctl limit maxfiles <value>" call
	# Also gitlib-ci needs the password to change the limits, while
	# travis-ci runs under root user. Limit setup must be in the same
	# call as tests runs call.
	# Tests: Temporary excluded replication/ suite with some tests
	#        from other suites by issues #4357 and #4370
	sudo -S launchctl limit maxfiles ${MAX_FILES} || : ; \
		launchctl limit maxfiles || : ; \
		ulimit -n ${MAX_FILES} || : ; \
		ulimit -n ; \
		sudo -S launchctl limit maxproc ${MAX_PROC} || : ; \
		launchctl limit maxproc || : ; \
		ulimit -u ${MAX_PROC} || : ; \
		ulimit -u ; \
		rm -rf /tmp/tnt ; \
		cd test && ./test-run.py --vardir /tmp/tnt --force $(TEST_RUN_EXTRA_PARAMS) \
			app/ app-tap/ box/ box-py/ box-tap/ engine/ engine_long/ long_run-py/ luajit-tap/ \
			replication-py/ small/ sql/ sql-tap/ swim/ unit/ vinyl/ wal_off/ xlog/ xlog-py/

test_osx: deps_osx test_osx_no_deps

###########
# FreeBSD #
###########

deps_freebsd:
	sudo pkg install -y git cmake gmake icu libiconv \
		python27 py27-yaml py27-six py27-gevent \
		autoconf automake libtool

build_freebsd:
	cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo -DENABLE_WERROR=ON ${CMAKE_EXTRA_PARAMS}
	gmake -j

test_freebsd_no_deps: build_freebsd
	cd test && python2.7 test-run.py --force $(TEST_RUN_EXTRA_PARAMS)

test_freebsd: deps_freebsd test_freebsd_no_deps

####################
# Sources tarballs #
####################

source:
	git clone https://github.com/packpack/packpack.git packpack
	TARBALL_COMPRESSOR=gz packpack/packpack tarball

# Push alpha and beta versions to <major>x bucket (say, 2x),
# stable to <major>.<minor> bucket (say, 2.2).
ifeq ($(TRAVIS_BRANCH),master)
GIT_DESCRIBE=$(shell git describe HEAD)
MAJOR_VERSION=$(word 1,$(subst ., ,$(GIT_DESCRIBE)))
MINOR_VERSION=$(word 2,$(subst ., ,$(GIT_DESCRIBE)))
else
MAJOR_VERSION=$(word 1,$(subst ., ,$(TRAVIS_BRANCH)))
MINOR_VERSION=$(word 2,$(subst ., ,$(TRAVIS_BRANCH)))
endif
BUCKET=tarantool.$(MAJOR_VERSION).$(MINOR_VERSION).src
ifeq ($(MINOR_VERSION),0)
BUCKET=tarantool.$(MAJOR_VERSION)x.src
endif
ifeq ($(MINOR_VERSION),1)
BUCKET=tarantool.$(MAJOR_VERSION)x.src
endif

source_deploy:
	pip install awscli --user
	aws --endpoint-url "${AWS_S3_ENDPOINT_URL}" s3 \
		cp build/*.tar.gz "s3://${BUCKET}/" \
		--acl public-read
