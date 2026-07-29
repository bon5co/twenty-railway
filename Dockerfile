# Railway-tuned Twenty CRM image.
#
# One image runs both roles of a Twenty deployment: the API/UI server and the
# background worker. The role is inferred from the start command (see
# railway-entrypoint.sh), so the Railway template does not have to ship the
# per-role migration flags as variables.
#
# Everything baked here is a value the deployer should never have to type.
# Railway's `templateGenerate` keeps a template variable's default ONLY when the
# live value is a Railway expression -- a literal is dropped and the variable
# publishes as "required, no value", so the deploy form opens asking for
# settings the image already knows. Baking them into the image is what keeps
# the published deploy form empty.
FROM twentycrm/twenty:v2.25.1

USER root
COPY railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod +x /usr/local/bin/railway-entrypoint.sh
USER 1000

ENV NODE_PORT=8080 \
    ENABLE_ALPINE_PRIVATE_NETWORKING=true \
    STORAGE_TYPE=S_3 \
    STORAGE_S3_NAME=twenty \
    STORAGE_S3_REGION=us-east-1 \
    LOGIC_FUNCTION_TYPE=DISABLED \
    CODE_INTERPRETER_TYPE=DISABLED

EXPOSE 8080

# Upstream's own entrypoint (/app/entrypoint.sh) still runs -- it is what
# initialises the schema on a first boot and applies upgrade migrations after.
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD ["node", "dist/main"]
