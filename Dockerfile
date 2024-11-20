FROM nginx:alpine  
COPY hello.txt /var/www/hello.txt  
COPY nginx.conf /etc/nginx/conf.d/default.conf