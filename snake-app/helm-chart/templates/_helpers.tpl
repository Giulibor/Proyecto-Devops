{{- define "snake-app.name" -}}
snake-app
{{- end }}

{{- define "snake-app.fullname" -}}
{{ include "snake-app.name" . }}
{{- end }}

{{- define "snake-app.labels" -}}
app.kubernetes.io/name: {{ include "snake-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}