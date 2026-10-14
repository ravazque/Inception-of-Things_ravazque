# Inception of Things

Inception of Things is a system administration project about Kubernetes, in
four steps: two virtual machines running K3s with Vagrant, three web
applications behind an Ingress, a K3d cluster deployed through GitOps with
Argo CD, and, as the bonus, a GitLab running inside the cluster as the Git
source.

## How it works

**Part 1.** Two virtual machines on the private network `192.168.56.0/24`:
`ravazqueS` (`192.168.56.110`) runs K3s in server mode (control plane) and
`ravazqueSW` (`192.168.56.111`) in agent mode. The agent joins with a token
shared through the `Vagrantfile`, so no node token is copied between the
machines; both scripts find the network interface from its IP address,
whatever name the provider gives it. SSH needs no password.

**Part 2.** One K3s server, `ravazqueS`, with three nginx applications, each
with its ConfigMap, Deployment and Service; `app2` runs three replicas. A
single Ingress routes by `Host` header: `app1.com` to app1, `app2.com` to
app2, and anything else to app3, the default backend.

**Part 3.** A K3d cluster (K3s inside Docker, no virtual machine) with the
namespaces `argocd` and `dev`. An Argo CD `Application` follows a public
GitHub repository and deploys `wil42/playground` (port 8888) in `dev`;
changing the image tag between `v1` and `v2` in Git and pushing redeploys it.

**Bonus.** The same cluster plus a `gitlab` namespace running GitLab CE. The
scripts create a root API token, a public project and the manifests through
the GitLab API, then point the Argo CD `Application` at the in-cluster GitLab,
so the whole GitOps loop runs locally.

## Dependencies

| Dependency | For | Debian / Ubuntu | Arch |
|---|---|---|---|
| Vagrant | p1, p2 | https://developer.hashicorp.com/vagrant/install | `vagrant` |
| libvirt with `vagrant-libvirt`, or VirtualBox | p1, p2 | `qemu-kvm libvirt-daemon-system`, then `vagrant plugin install vagrant-libvirt` | `libvirt qemu-base`, then the same plugin |
| Docker, with the daemon running | p3, bonus | `docker.io` | `docker` |
| `curl`, GNU Make | everything | `curl make` | `curl make` |
| `kubectl`, `k3d`, `argocd` | p3, bonus | downloaded by the scripts into `~/.local/bin`, without `sudo` | same |

The virtual machines run Ubuntu 22.04 (`generic/ubuntu2204`), a box published
for both providers. The bonus needs about 8 GB of free RAM: GitLab CE is a
3.5 GB image whose first boot takes 10 to 20 minutes.

## Build and run

```
make install   # checks Vagrant, the provider and Docker
make p1        # PROVIDER=libvirt (default) or PROVIDER=virtualbox
make p2
make p3        # K3d cluster with Argo CD
make bonus     # the same with a local GitLab
make clean     # destroys the p1 / p2 machines and the iot cluster
```

`make` alone lists the targets. Each part folder has its own `README.md` with
the commands that test, stop and destroy it:

- [`srcs/p1/README.md`](../srcs/p1/README.md): K3s server and agent with Vagrant
- [`srcs/p2/README.md`](../srcs/p2/README.md): three apps behind an Ingress
- [`srcs/p3/README.md`](../srcs/p3/README.md): K3d and Argo CD
- [`srcs/bonus/README.md`](../srcs/bonus/README.md): the local GitLab

## Layout

```
Inception-of-Things/
├── Makefile           # install check, one target per part, clean
├── docs/              # project documentation
├── srcs/p1/           # Vagrantfile, scripts/ (server and worker provisioning)
├── srcs/p2/           # Vagrantfile, scripts/, confs/ (apps and Ingress)
├── srcs/p3/           # scripts/install.sh, confs/ (Argo CD Application, manifests)
└── srcs/bonus/        # scripts/ (GitLab, Argo CD), confs/ (GitLab, Application, manifests)
```

## References

Project tools:

- Kubernetes documentation — <https://kubernetes.io/docs/home/>
- Kubernetes concepts: Deployment, Service, Ingress —
  <https://kubernetes.io/docs/concepts/workloads/controllers/deployment/>,
  <https://kubernetes.io/docs/concepts/services-networking/service/>,
  <https://kubernetes.io/docs/concepts/services-networking/ingress/>
- K3s — <https://docs.k3s.io/>
- K3d — <https://k3d.io/>
- Vagrant — <https://developer.hashicorp.com/vagrant/docs>
- vagrant-libvirt provider — <https://vagrant-libvirt.github.io/vagrant-libvirt/>
- Docker Engine — <https://docs.docker.com/engine/>
- Traefik Kubernetes Ingress — <https://doc.traefik.io/traefik/providers/kubernetes-ingress/>
- Argo CD — <https://argo-cd.readthedocs.io/en/stable/>
- Argo CD `Application` specification —
  <https://argo-cd.readthedocs.io/en/stable/operator-manual/application.yaml>
- GitLab CE Docker image — <https://docs.gitlab.com/ee/install/docker.html>
- GitLab REST API — <https://docs.gitlab.com/ee/api/rest/>

Application used in Part 3 and the bonus:

- `wil42/playground` on Docker Hub — <https://hub.docker.com/r/wil42/playground>
  (port `8888`, tags `v1` and `v2`)
