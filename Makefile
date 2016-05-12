all: pull ${SOURCES} binary

.PHONY: pull containers compilers-rump-base-common compilers-rump-base-hw compilers-rump-base-xen compilers-rump-go-hw compilers-rump-go-xen compilers-rump-nodejs-hw compilers-rump-nodejs-xen compilers-osv-java compilers boot-creator image-creator vsphere-client qemu-util utils

#pull containers
pull:
	echo "Pullling containers from docker hub"
	docker pull projectunik/vsphere-client
	docker pull projectunik/image-creator
	docker pull projectunik/boot-creator
	docker pull projectunik/qemu-img
	docker pull projectunik/compilers-osv-java
	docker pull projectunik/compilers-rump-go-hw
	docker pull projectunik/compilers-rump-go-xen
	docker pull projectunik/compilers-rump-nodejs-hw
	docker pull projectunik/compilers-rump-nodejs-xen
	docker pull projectunik/compilers-rump-base-xen
	docker pull projectunik/compilers-rump-base-hw
	docker pull projectunik/compilers-rump-base-common
#------

#build containers from source
containers: compilers utils
	echo "Built containers from source"

#compilers
compilers: compilers-rump-go-hw compilers-rump-go-xen compilers-rump-nodejs-hw compilers-rump-nodejs-xen compilers-osv-java

compilers-rump-base-common:
	cd containers/compilers/rump/base && docker build -t projectunik/$@ -f Dockerfile.common .

compilers-rump-base-hw: compilers-rump-base-common
	cd containers/compilers/rump/base && docker build -t projectunik/$@ -f Dockerfile.hw .

compilers-rump-base-xen: compilers-rump-base-common
	cd containers/compilers/rump/base && docker build -t projectunik/$@ -f Dockerfile.xen .

compilers-rump-go-hw: compilers-rump-base-hw
	cd containers/compilers/rump/go && docker build -t projectunik/$@ -f Dockerfile.hw .

compilers-rump-go-xen: compilers-rump-base-xen
	cd containers/compilers/rump/go && docker build -t projectunik/$@ -f Dockerfile.xen .

compilers-rump-nodejs-hw: compilers-rump-base-hw
	cd containers/compilers/rump/nodejs && docker build -t projectunik/$@ -f Dockerfile.hw .

compilers-rump-nodejs-xen: compilers-rump-base-xen
	cd containers/compilers/rump/nodejs && docker build -t projectunik/$@ -f Dockerfile.xen .

compilers-osv-java:
	cd containers/compilers/osv/java-compiler && GOOS=linux go build && docker build -t projectunik/$@ .

#utils
utils: boot-creator image-creator vsphere-client qemu-util

boot-creator:
	cd containers/utils/boot-creator && GO15VENDOREXPERIMENT=1 GOOS=linux go build && docker build -t projectunik/$@ -f Dockerfile . && rm boot-creator

image-creator:
	cd containers/utils/image-creator && GO15VENDOREXPERIMENT=1 GOOS=linux go build && docker build -t projectunik/$@ -f Dockerfile . && rm image-creator

vsphere-client:
	cd containers/utils/vsphere-client && mvn package && docker build -t projectunik/$@ -f Dockerfile . && rm -rf target

qemu-util:
	cd containers/utils/qemu-util && docker build -t projectunik/$@ -f Dockerfile .

#------

#binary
SOURCEDIR=.
SOURCES := $(shell find $(SOURCEDIR) -name '*.go')

BINARY=unik
UNAME=$(uname)

binary: ${SOURCES}
	ifeq ($(UNAME),Linux)
		TARGET_OS=linux
	endif
	ifeq (Darwin,$UNAME)
		TARGET_OS=darwin
	endif
	ifeq (,$TARGET_OS)
		echo "Unknown platform $UNAME"
		exit 1
	endif
	echo Building for platform $UNAME
	docker build -t projectunik/$@ -f Dockerfile .
	mkdir -p ./_build
	docker run --rm -v $PWD/_build:/opt/build -e TARGET_OS=$TARGET_OS projectunik/$@
	docker rmi -f projectunik/$@
	echo "Install finished! UniK binary can be found at $PWD/_build/unik"

#----

#clean up
.PHONY: uninstall remove-containers clean

uninstall:
	rm $(which ${BINARY})

remove-containers:
	-docker rmi -f projectunik/vsphere-client
	-docker rmi -f projectunik/image-creator
	-docker rmi -f projectunik/boot-creator
	-docker rmi -f projectunik/compilers-osv-java
	-docker rmi -f projectunik/compilers-rump-go-xen
	-docker rmi -f projectunik/compilers-rump-go-hw
	-docker rmi -f projectunik/compilers-rump-nodejs-hw
	-docker rmi -f projectunik/compilers-rump-nodejs-xen
	-docker rmi -f projectunik/compilers-rump-base-xen
	-docker rmi -f projectunik/compilers-rump-base-hw
	-docker rmi -f projectunik/compilers-rump-base-common

clean:
	if [ -f ${BINARY} ] ; then rm ${BINARY} ; fi
#---
