FROM nginx:1.13.7
RUN apt-get update && \
    apt-get install -y gettext bash && \
    apt-get clean
RUN rm /etc/nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY . /.

