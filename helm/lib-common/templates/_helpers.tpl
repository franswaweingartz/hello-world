{{/*
Resolve the app name: use .Values.nameOverride if set, otherwise fall back to
.Release.Name. This avoids hardcoding "lib-common" (the library chart name)
into labels when the template is called from a parent chart.
*/}}
{{- define "lib-common.name" -}}
{{- .Values.nameOverride | default .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate standard labels for all resources.
*/}}
{{- define "lib-common.labels" -}}
app.kubernetes.io/name: {{ include "lib-common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag | default "0.0.0" | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Generate selector labels used by Services to find Pods.
*/}}
{{- define "lib-common.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lib-common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Generate a fullname for resources.
*/}}
{{- define "lib-common.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "lib-common.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
