# athenz-zms-server

## kustomization

```
kubectl apply -k ./kustomize
```

## Custom Solution Templates

Default Athenz solution templates stay in the normal `athenz-zms-conf`
ConfigMap from:

```
kustomize/conf/solution_templates.json
```

To add custom solution templates, create an optional ConfigMap named
`athenz-zms-custom-solution-templates`:

```sh
kubectl -n athenz create configmap athenz-zms-custom-solution-templates \
  --from-file=custom_solution_templates.json=your-solution-template.json \
  --dry-run=client -o yaml | kubectl apply -f -
```

The ConfigMap is optional. If it is absent, ZMS starts with the default
`solution_templates.json` unchanged.

If the custom ConfigMap is present, the ZMS Docker entrypoint copies the default
config into a writable runtime directory, merges the custom templates under the
top-level `templates` object, and starts ZMS with the merged file:

```
/var/run/athenz/zms-conf/solution_templates.json
```

Custom templates must use the same JSON shape as the default file:

```json
{
  "templates": {}
}
```

If a custom template uses the same name as a default template, the custom
definition wins. Delete `athenz-zms-custom-solution-templates` and restart ZMS
to return to the default templates only.
