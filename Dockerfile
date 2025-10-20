# Dockerfile
FROM nginx:stable-alpine
# remove default nginx site
RUN rm -rf /usr/share/nginx/html/*
# copy build output or static files to nginx html
COPY . /usr/share/nginx/html
# ensure nginx listens on 80 (default)
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
