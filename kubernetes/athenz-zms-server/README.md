# athenz-zms-server

## kustomization

```
kubectl apply -k ./kustomize
```

## Custom Solution Templates

Default Athenz solution templates are generated into the
`athenz-zms-default-solution-templates` ConfigMap from:

```
kustomize/conf/solution_templates.json
```

Custom solution templates are generated separately into the
`athenz-zms-custom-solution-templates` ConfigMap from:

```
kustomize/conf/custom_solution_templates.json
```

At pod startup, the `athenz-zms-conf-merge` init container merges the default
and custom template files into the final ZMS config directory. ZMS still reads
one file:

```
/opt/athenz/zms/conf/zms_server/solution_templates.json
```

Add local custom templates under the top-level `templates` object in
`custom_solution_templates.json`, then re-apply the kustomization and restart
ZMS. If a custom template uses the same name as a default template, the custom
definition wins.
