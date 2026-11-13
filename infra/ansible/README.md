# Ansible: ShopSphere Minikube host

`site.yml` describes the Minikube EC2 host (Ubuntu 24.04) that Terraform creates in
[devops-lab-infra/terraform-v2](https://github.com/Aakash17-hub/devops-lab-infra/tree/main/terraform-v2).
It can run on the host itself or from the bastion over SSH.

## What it manages

| Tag | What |
|---|---|
| `base` | 4G swapfile (+ fstab), `docker.io`, `conntrack`, Docker enabled, `ubuntu` in the `docker` group |
| `tools` | `minikube`, `kubectl`, `helm` at pinned versions, installed only if the version differs; downloads are checked against the publisher's sha256 |
| `runner` | GitLab Runner apt key + repository + package |
| `users` | `jenkins-deploy` user; its `authorized_keys` restricted to `from="10.0.2.160"` with no port/agent/X11 forwarding; `.ssh` and `.kube` directories |
| `cluster` | optional (`-e minikube_start=true`): `minikube start` with the pinned Kubernetes version and `metrics-server` |
| `kubeconfig` | optional (`-e build_deploy_kubeconfig=true`): builds `jenkins-deploy`'s kubeconfig from the `jenkins-deployer` ServiceAccount token (`no_log`) |

Pinned versions are variables at the top of `site.yml`.

## What it does not manage (on purpose)

- **GitLab Runner registration**: it needs a token, so `sudo gitlab-runner register` stays manual.
- **Secrets**: the Jenkins public key is passed in from an untracked file; tokens are never stored in this repo.
- **Cluster bootstrap**: `k8s/00-namespace.yaml`, `k8s/01-rbac.yaml` and `bootstrap/*.yaml` are applied once by an admin, because the CI identity is not allowed to create RBAC.
- **The GitLab Runner's kubeconfig** (`ci-deployer` token): built by hand for now, see the devops-lab-infra `REBUILD.md`.
- **Workloads**: manifests, policies and monitoring are applied by the CI/CD pipelines and Helm, not Ansible.

## Run

```bash
sudo apt-get install -y ansible-core
cp vars.local.yml.example vars.local.yml      # then put the real public key in it

# On the host itself
ansible-playbook -i localhost, -c local site.yml -e @vars.local.yml --check --diff   # dry run
ansible-playbook -i localhost, -c local site.yml -e @vars.local.yml --diff           # apply

# Or from the bastion, on a fresh host, including the cluster
ansible-playbook -i '10.0.1.237,' -u ubuntu site.yml -e @vars.local.yml -e minikube_start=true
```

## Verified

- **Against the existing host** (ansible-core 2.16.3): the dry run showed only a drifted `.kube` directory (owned by root, mode 755); the real run fixed it (`changed=1`) and an immediate second run reported `changed=0`.
- **From scratch, 13 Nov 2026**: run from the bastion against a freshly created instance with `minikube_start=true`, then `--tags kubeconfig` after the bootstrap manifests. The cluster came up (Kubernetes v1.37.0), the kubeconfig task worked, and both GitLab CI and the Jenkins `shopsphere-deploy` job deployed the workloads.

## Notes

- The first dry run on the real host found drift I had not expected: the GitLab installer had already created a binary keyring at a different path than my first draft used, which would have produced a duplicate apt source. The playbook now matches the installer's path.
- The from-scratch run found a bug the existing host had hidden: the GitLab Runner repository was added with `update_cache: false` and the install task did not refresh the cache either, so apt could not see the package on a fresh host. The install now refreshes the cache whenever the repository task changes.
- `ansible.builtin.apt_repository` is deprecated in newer ansible-core. It still works on 2.16; switching to `deb822_repository` is on the list.
