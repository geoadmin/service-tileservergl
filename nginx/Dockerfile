FROM nginx:1.13.7
RUN apt-get update && \
    apt-get install -y gettext bash python-pip && \
    apt-get clean
RUN pip install Mako==1.0.7
RUN rm /etc/nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY nginx.conf.in /etc/nginx/nginx.conf.in
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY maputnik-editor /usr/src/maputnik-editor
ENV MAPUTNIK_ROOT=/usr/src/maputnik-editor/public
ENTRYPOINT ["/docker-entrypoint.sh"]
