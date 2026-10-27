{{- define "athenz-showcase.image" -}}
{{- $root := index . 0 -}}
{{- $original := index . 1 -}}
{{- $last := last (splitList "/" $original) -}}
{{- $name := first (splitList ":" $last) -}}
{{- if hasKey $root.Values.images $name -}}
{{- index $root.Values.images $name -}}
{{- else if hasPrefix "ghcr.io/ctyano/" $original -}}
  {{- if has $name (list "athenz-db" "athenz-cli" "athenz-zms-server" "athenz-zts-server" "athenz-ui" "athenz-zms-syncer") -}}
    {{- printf "%s%s:%s" $root.Values.registries.internal $name $root.Values.athenzImageTag -}}
  {{- else -}}
    {{- printf "%s%s:%s" $root.Values.registries.external $name (last (splitList ":" $last)) -}}
  {{- end -}}
{{- else if hasPrefix "docker.io/" $original -}}
{{- printf "%s/%s" (trimSuffix "/" $root.Values.registries.dockerio) (trimPrefix "docker.io/" $original) -}}
{{- else if hasPrefix "quay.io/" $original -}}
{{- printf "%s/%s" (trimSuffix "/" $root.Values.registries.quayio) (trimPrefix "quay.io/" $original) -}}
{{- else -}}
{{- $original -}}
{{- end -}}
{{- end -}}

{{- define "athenz-showcase.walk" -}}
{{- $root := index . 0 -}}
{{- $node := index . 1 -}}
{{- if kindIs "map" $node -}}
  {{- range $key, $value := $node -}}
    {{- if and (eq $key "image") (kindIs "string" $value) -}}
      {{- $_ := set $node $key (include "athenz-showcase.image" (list $root $value)) -}}
    {{- else if and (eq $key "imagePullPolicy") (kindIs "string" $value) -}}
      {{- $_ := set $node $key $root.Values.imagePullPolicy -}}
    {{- else -}}
      {{- include "athenz-showcase.walk" (list $root $value) -}}
    {{- end -}}
  {{- end -}}
{{- else if kindIs "slice" $node -}}
  {{- range $node -}}
    {{- include "athenz-showcase.walk" (list $root .) -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "athenz-showcase.cliImage" -}}
{{- if .Values.hooks.cliImage -}}{{ .Values.hooks.cliImage }}{{- else -}}{{ include "athenz-showcase.image" (list . "ghcr.io/ctyano/athenz-cli:latest") }}{{- end -}}
{{- end -}}

{{- define "athenz-showcase.hookLabels" -}}
app.kubernetes.io/name: athenz-showcase
app.kubernetes.io/instance: {{ .Release.Name | quote }}
app.kubernetes.io/component: {{ .Values.phase | quote }}
{{- end -}}
