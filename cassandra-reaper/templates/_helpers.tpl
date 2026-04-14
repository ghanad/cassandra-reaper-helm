{{- define "cassandra-reaper.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cassandra-reaper.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "cassandra-reaper.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "cassandra-reaper.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cassandra-reaper.labels" -}}
helm.sh/chart: {{ include "cassandra-reaper.chart" . }}
app.kubernetes.io/name: {{ include "cassandra-reaper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.extraLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{- define "cassandra-reaper.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cassandra-reaper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "cassandra-reaper.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "cassandra-reaper.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "cassandra-reaper.hasSecretEnv" -}}
{{- $hasReaperAuth := and .Values.reaper.auth.enabled .Values.reaper.auth.username .Values.reaper.auth.password -}}
{{- $hasReadOnlyAuth := and .Values.reaper.auth.readOnly.username .Values.reaper.auth.readOnly.password -}}
{{- $hasJwtSecret := ne (default "" .Values.reaper.auth.jwtSecret) "" -}}
{{- $hasCassAuth := and .Values.reaper.cassandra.auth.enabled .Values.reaper.cassandra.auth.username .Values.reaper.cassandra.auth.password -}}
{{- $hasExtraSecretEnv := gt (len .Values.extraSecretEnv) 0 -}}
{{- if or $hasReaperAuth $hasReadOnlyAuth $hasJwtSecret $hasCassAuth $hasExtraSecretEnv -}}
true
{{- end -}}
{{- end -}}
