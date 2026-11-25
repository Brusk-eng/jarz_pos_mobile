FROM nginx:alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy our nginx config
COPY nginx.conf /etc/nginx/conf.d/pos.conf

# Copy the Flutter web build (will be placed here during deployment)
COPY web/ /usr/share/nginx/html/pos/

# The Jarz Studio web build (deploy_web.ps1 -App studio); /studio/ is served beside /pos/.
COPY studio-web/ /usr/share/nginx/html/studio/

EXPOSE 80
