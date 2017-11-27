FROM nginx:1.13.3
RUN apt-get update && apt-get install -y gettext bash
RUN rm /etc/nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY . /.

