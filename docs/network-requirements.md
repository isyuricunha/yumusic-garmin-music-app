# Network Requirements (HTTPS)

YuMusic relies on Garmin's `Communications` module to access your server. Garmin enforces extremely strict networking rules.

## Why HTTP (`http://`) Does Not Work
1. **Garmin Connect Mobile Proxy:** On Android and modern iOS devices, the Garmin Connect app proxies watch requests. Mobile operating systems strictly enforce App Transport Security (ATS) and Network Security Configuration, **blocking plain-text HTTP traffic** before it even leaves your phone. You will see error `-1001 (SECURE_CONNECTION_REQUIRED)`.
2. **Wi-Fi Downloader Stack:** Audio syncs occur over Wi-Fi directly from the watch. The Garmin Wi-Fi network stack requires a secure connection to download audio streams. Attempting HTTP downloads over Wi-Fi usually results in error `0` or `-300` because the OS abruptly terminates the insecure connection.

## Why Local IPs (e.g., `192.168.1.100`) Often Fail
If you configure a local IP, the watch will try to reach it through your phone's Bluetooth connection. If your phone is on Cellular data (4G/5G) instead of your local Wi-Fi, the proxy will instantly time out (`-300`). Additionally, Garmin still expects an SSL certificate even on local IPs.

## How to Set Up Your Server Correctly
To use YuMusic, you must expose your server securely over HTTPS with a valid, publicly trusted SSL certificate (self-signed certificates are rejected by Garmin). 

Popular and free ways to achieve this:
- **Cloudflare Tunnels (Zero Trust)**: The easiest method. Cloudflare generates the HTTPS certificate automatically and tunnels traffic safely to your local server without port forwarding.
- **Tailscale**: Using Tailscale's "MagicDNS" and "HTTPS Certs" features provides a secure, encrypted domain name for your server.
- **Reverse Proxy**: Use Nginx Proxy Manager, Caddy, or Traefik with Let's Encrypt certificates.
