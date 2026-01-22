{{- define "athenz-stack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "athenz-stack.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "athenz-stack.labels" -}}
app.kubernetes.io/name: {{ include "athenz-stack.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "athenz-stack.db.fullname" -}}
{{- printf "%s-db" (include "athenz-stack.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "athenz-stack.zms.fullname" -}}
{{- printf "%s-zms" (include "athenz-stack.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "athenz-stack.zts.fullname" -}}
{{- printf "%s-zts" (include "athenz-stack.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "athenz-stack.ui.fullname" -}}
{{- printf "%s-ui" (include "athenz-stack.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "athenz-stack.zmsURL" -}}
{{- $host := printf "%s.%s.svc.cluster.local" (include "athenz-stack.zms.fullname" .) .Release.Namespace -}}
{{- printf "%s:%d" $host (int .Values.zms.port) -}}
{{- end -}}
