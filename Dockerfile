# Use nginx alpine for lightweight production image
FROM nginx:1.25-alpine

# Build args for cache invalidation
ARG DEPLOYMENT_MODE=production
ARG BUILD_TIMESTAMP=unknown

# Install wget for health checks
RUN apk add --no-cache wget

# Copy static files
COPY index.html /usr/share/nginx/html/
COPY example_video.mov /usr/share/nginx/html/
COPY girl_influencers_studio.png /usr/share/nginx/html/
COPY flowchart.png /usr/share/nginx/html/
COPY ecommerce_teaching.png /usr/share/nginx/html/

# Create build info and health endpoints
RUN DETECTED_MODE=$(grep "const DEPLOYMENT_MODE = " /usr/share/nginx/html/index.html | sed "s/.*const DEPLOYMENT_MODE = '\([^']*\)'.*/\1/" 2>/dev/null || echo "unknown") && \
    printf "mode=%s\nbuild_timestamp=%s\nbuild_date=%s\n" "$DETECTED_MODE" "$BUILD_TIMESTAMP" "$(date)" > /usr/share/nginx/html/build-info.txt && \
    echo "healthy" > /usr/share/nginx/html/health

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
        
        # Security headers (PayPal-compatible)
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;
        
        # Content Security Policy for PayPal integration
        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://www.paypal.com https://www.paypalobjects.com https://js.paypal.com https://c.paypal.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdnjs.cloudflare.com; font-src 'self' https://fonts.gstatic.com https://cdnjs.cloudflare.com; img-src 'self' data: https:; frame-src https://www.paypal.com https://js.paypal.com; connect-src 'self' https://www.paypal.com https://api.paypal.com https://api.sandbox.paypal.com;" always;
        
        # Main site - Reduced caching for mode switching
        location / {
            try_files \$uri \$uri/ /index.html;
            expires 1m;
            add_header Cache-Control "public, no-transform, must-revalidate";
            add_header Pragma "no-cache";
        }
        
        # Build info endpoint for cache busting
        location /build-info.txt {
            access_log off;
            expires -1;
            add_header Cache-Control "no-cache, no-store, must-revalidate";
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