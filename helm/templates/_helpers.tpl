{{/* Expand the chart name. */}}
{{- define "talqo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Full release-scoped name. */}}
{{- define "talqo.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "talqo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "talqo.labels" -}}
helm.sh/chart: {{ include "talqo.chart" . }}
{{ include "talqo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "talqo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "talqo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "talqo.secretName" -}}
{{- if .Values.existingSecret }}
{{- .Values.existingSecret }}
{{- else }}
{{- include "talqo.fullname" . }}
{{- end }}
{{- end }}

{{- define "talqo.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "talqo.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/* Bitnami service host for the app's DATABASE_URL. */}}
{{- define "talqo.postgresqlHost" -}}
{{- if .Values.postgresql.fullnameOverride }}
{{- .Values.postgresql.fullnameOverride }}
{{- else }}
{{- printf "%s-postgresql" (include "talqo.fullname" .) }}
{{- end }}
{{- end }}

{{/* Docling endpoint for the app. Fails fast when no Docling is configured. */}}
{{- define "talqo.doclingUrl" -}}
{{- if .Values.docling.enabled }}
{{- printf "http://%s-docling:5001" (include "talqo.fullname" .) }}
{{- else }}
{{- required "Set docling.externalUrl when docling.enabled=false." .Values.docling.externalUrl }}
{{- end }}
{{- end }}
