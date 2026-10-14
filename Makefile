PROVIDER	?= $(or $(VAGRANT_DEFAULT_PROVIDER),libvirt)
CLUSTER		= iot


help:
	@echo "make install    check everything the four parts need"
	@echo "make p1         part 1: two K3s machines with Vagrant (PROVIDER=libvirt|virtualbox)"
	@echo "make p2         part 2: three apps behind an Ingress, one K3s machine"
	@echo "make p3         part 3: K3d cluster with Argo CD, on the host"
	@echo "make bonus      part 3 with a local GitLab (about 8 GB of free RAM)"
	@echo "make clean      destroy the p1 / p2 machines and the $(CLUSTER) cluster"

install: vagrant-check docker-check
	@echo "dependencies ready: kubectl, k3d and argocd are downloaded into ~/.local/bin by p3 and bonus"

vagrant-check:
	@command -v vagrant >/dev/null || { echo "vagrant not found: install Vagrant (https://developer.hashicorp.com/vagrant/install)" >&2; exit 1; }
ifeq ($(PROVIDER),libvirt)
	@vagrant plugin list | grep -q vagrant-libvirt || { echo "vagrant-libvirt not found: vagrant plugin install vagrant-libvirt, or use PROVIDER=virtualbox" >&2; exit 1; }
else
	@command -v VBoxManage >/dev/null || { echo "VirtualBox not found: install VirtualBox, or use PROVIDER=libvirt" >&2; exit 1; }
endif

docker-check:
	@command -v docker >/dev/null || { echo "docker not found: install Docker Engine" >&2; exit 1; }
	@docker info >/dev/null 2>&1 || { echo "the docker daemon is not running: sudo systemctl start docker" >&2; exit 1; }
	@command -v curl >/dev/null || { echo "curl not found: install curl" >&2; exit 1; }

p1 p2: vagrant-check
	cd srcs/$@ && vagrant up --provider=$(PROVIDER)

p3 bonus: docker-check
	cd srcs/$@ && ./scripts/install.sh

clean:
	-cd srcs/p1 && vagrant destroy -f
	-cd srcs/p2 && vagrant destroy -f
	-command -v k3d >/dev/null && k3d cluster delete $(CLUSTER)

.PHONY: help install vagrant-check docker-check p1 p2 p3 bonus clean
