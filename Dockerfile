FROM gcr.io/kaniko-project/executor:debug-v1.0.0

LABEL maintainer="İbrahim Akyel <ibrahim@ibrahimakyel.com>" \
	org.label-schema.name="Drone Kaniko" \
	org.label-schema.vendor="İbrahim Akyel" \
	org.label-schema.schema-version="1.0"

COPY plugin.sh /kaniko/plugin.sh
ENTRYPOINT [ "/kaniko/plugin.sh" ]
