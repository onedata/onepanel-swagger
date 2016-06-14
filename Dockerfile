FROM busybox

ADD pub-artefact /

ADD swagger.json /artefact/swagger.json 
RUN ["/bin/busybox","sh","/pub-artefact","/artefact","/usr/share/nginx/html/doc/swagger/onepanel"]
RUN ["/bin/busybox","sh","/pub-artefact","/artefact","/var/www/html/docs/doc/swagger/onepanel"]

ADD generated/static/onepanel-static.html /artefact/generated/static/onepanel-static.html

RUN ["/bin/busybox","sh","/pub-artefact","/artefact/generated/static","/usr/share/nginx/html/doc/advanced/rest/swagger-static-onepanel"]
RUN ["/bin/busybox","sh","/pub-artefact","/artefact/generated/static","/var/www/html/docs/doc/advanced/rest/swagger-static-onepanel"]

#Otherwise docer-compose up fails randomly, seems to work with docker 1.10+
CMD ["/bin/busybox","tail","-f","/dev/null"]
