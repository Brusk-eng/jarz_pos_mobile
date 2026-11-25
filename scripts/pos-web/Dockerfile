FROM nginx:alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy our nginx config
COPY nginx.conf /etc/nginx/conf.d/pos.conf

# Copy the Flutter web build (will be placed here during deployment)
COPY web/ /usr/share/nginx/html/pos/

EXPOSE 80
