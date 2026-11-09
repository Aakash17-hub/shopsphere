# Ansible: ShopSphere Minikube host

`site.yml` describes the Minikube EC2 host (Ubuntu 24.04) that Terraform creates in `../terraform`.
It runs on the host itself, so no inventory or SSH setup is needed.

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
- **Workloads**: manifests, policies and monitoring are applied by the CI/CD pipelines, not Ansible.

## Run

```bash
sudo apt-get install -y ansible-core
cp vars.local.yml.example vars.local.yml      # then put the real public key in it
ansible-playbook -i localhost, -c local site.yml -e @vars.local.yml --check --diff   # dry run
ansible-playbook -i localhost, -c local site.yml -e @vars.local.yml --diff           # apply
```

## Verified

Run against the existing host (ansible-core 2.16.3): the dry run showed only a drifted `.kube` directory (owned by root, mode 755);
the real run fixed it (`changed=1`) and an immediate second run reported `changed=0`.

Not yet verified: a from-scratch run on a fresh instance, the `cluster` tasks and the `kubeconfig` task.

## Notes

- The first dry run on the real host found drift I had not expected: the GitLab installer had already created a binary keyring at a different path than my first draft used, which would have produced a duplicate apt source. The playbook now matches the installer's path.
- `ansible.builtin.apt_repository` is deprecated in newer ansible-core. It still works on 2.16; switching to `deb822_repository` is on the list.
