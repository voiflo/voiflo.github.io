# Use nginx alpine for lightweight production image
FROM nginx:1.25-alpine

# Install wget for health checks
RUN apk add --no-cache wget

# Copy static files
COPY index.html /usr/share/nginx/html/
COPY example_video.mov /usr/share/nginx/html/
COPY girl_influencers_studio.png /usr/share/nginx/html/
COPY flowchart.png /usr/share/nginx/html/
COPY ecommerce_teaching.png /usr/share/nginx/html/
COPY retail_teaching.png /usr/share/nginx/html/

# Create a simple health check endpoint
RUN echo "healthy" > /usr/share/nginx/html/health

# Create custom nginx config that works with non-root user
RUN mkdir -p /tmp/nginx && \
    chown -R nginx:nginx /tmp/nginx && \
    chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

# Create custom nginx configuration that works with non-root user
COPY <<EOF /etc/nginx/nginx.conf
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /tmp/nginx/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                   '\$status \$body_bytes_sent "\$http_referer" '
                   '"\$http_user_agent" "\$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    server {
        listen 8080;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;
        
        # Security headers
        add_header X-Frame-Options "DENY" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        
        # Main site
        location / {
            try_files \$uri \$uri/ /index.html;
            expires 5m;
            add_header Cache-Control "public, no-transform";
        }
        
        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\\n";
            add_header Content-Type text/plain;
        }
        
        # Static assets caching
        location ~* \\.(css|js|png|jpg|jpeg|gif|ico|svg)\$ {
            expires 1d;
            add_header Cache-Control "public, no-transform";
        }
        
        # Video files caching and proper headers
        location ~* \\.(mp4|mov|avi|mkv|webm)\$ {
            expires 1d;
            add_header Cache-Control "public, no-transform";
            add_header Accept-Ranges bytes;
        }
    }
}
EOF

# Switch to non-root user
USER nginx

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/health || exit 1

# Expose port
EXPOSE 8080

# Labels for metadata
LABEL maintainer="Voiflo <voiflo.community@gmail.com>" \
      version="1.0.0" \
      description="Premium landing page for digital influencer training"

# Start nginx
CMD ["nginx", "-g", "daemon off;"]