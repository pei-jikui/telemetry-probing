# telemetry-probing


## Install telemetry and appsvcs RPMs to BIG-IP

```
$ ansible-playbook -i conf.d/env.ini auto/install-as3.yml -e reinstall=1
$ ansible-playbook -i conf.d/env.ini auto/install-ts.yml -e reinstall=1
```

Where `-e reinstall=1` is used to force re-install.

## Configure ts with telemetry settings in conf.d/ts.json.j2

```
$ ansible-playbook -i conf.d/env.ini auto/config-ts.yml
```

## Deploy/Remove BIG-IP resources through AS3

```
# Deploy pools(and members) together with appointed healthmonitors in Common partition.
$ ansible-playbook -i conf.d/env.ini -e @conf.d/resources.yml deploy-resources.yml

# Remove all pools/members/healthmonitors.
$ ansible-playbook -i conf.d/env.ini remove-resources.yml
```
