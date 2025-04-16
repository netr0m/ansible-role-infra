# Authentik

## Initial configuration
1. After deploying, navigate to the Authentik dashboard (e.g. `https://authentik.<DOMAIN>.<tld>/if/flow/initial-setup/`. See `infra_authentik_fqdn`)
2. Create the admin user

## Configure authentik as a "Forward Auth" proxy

Firstly, navigate to the [Admin interface](https://authentik.<DOMAIN>.<tld>/if/admin/)

### Create the Application and Application Provider
1. Under [Applications](https://authentik.<DOMAIN>.<tld>/if/admin/#/core/applications), click "Create with wizard"
2. Provide a name for the application (e.g., "Traefik"), and click "Next"
3. Select "Proxy Provider" as the Provider Type, and click "Next"
4. Under "Authorization flow", select the "explicit-auth" option
5. Select "Forward auth (domain level)", and enter the "Authentication URL" (e.g., `authentik.<DOMAIN>.<tld>`) and "Cookie domain" (e.g. `<DOMAIN>.<tld>`). Click "Next"
6. For "Bindings", click "Next" (leave as-is)
7. Click "Submit" to create the Application and Provider

### Configure the Outpost
1. Navigate to [Outposts](https://authentik.<DOMAIN>.<tld>/if/admin/#/outpost/outposts), 
2. Click the "Edit" button for the "authentik Embedded Outpost"
3. Highlight the Application you created above (left-hand side), and click the right arrow icon to select the Application
4. Click "Update" to save the change
