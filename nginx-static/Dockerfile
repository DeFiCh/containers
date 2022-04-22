FROM docker.io/nginx
ARG PORT={{ .Env.PORT }}

COPY default.conf /etc/nginx/conf.d/default.conf
RUN mkdir -p /srv/www

EXPOSE $PORT