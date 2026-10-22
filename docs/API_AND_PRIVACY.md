# Tibber API, security, and privacy

TibberConnect calls `https://api.tibber.com/v1-beta/gql` with an identifying
User-Agent. Tibber documents a limit of **100 requests in 5 minutes per IP**.
Prices are cached; delayed consumption is fetched separately and less often.
Retries use bounded exponential backoff and jitter.

TibberLive first reads `realTimeConsumptionEnabled` and the dynamic
`websocketSubscriptionUrl`, then uses the `graphql-transport-ws` subprotocol.
Tibber permits at most two live WebSockets. Authentication failures are not
retried with the same token.

The official live schema provides `signalStrength` but no supported battery charge
or battery-voltage field. `batteryMaintenance` is only a calendar reminder and
never a measured battery level. The default is 365 days for a standard commercially available battery,
with a warning 30 days in advance. Actual life
varies by chemistry, meter, radio conditions, and setup history; users may set
`batteryLifetimeDays` after making their own informed choice.

Tokens are stored through FHEM protected key-value storage. They must not appear
in definitions, logs, screenshots, issues, release files, or diagnostic output.
For backward compatibility, a token found in a legacy definition is copied to
protected storage and a token-free `modify <name> TibberConnect` command is
shown. The user must run that command and save; the module deliberately does not
rewrite an existing definition automatically.
Home IDs, addresses, consumption, costs, and live measurements are personal data.
Sanitize them before sharing. OAuth is appropriate for a distributed third-party
application; personal access tokens are intended for the owner's own integration.

Official sources:

- <https://developer.tibber.com/docs/guides/calling-api>
- <https://developer.tibber.com/api/reference.md>

No Data API capability is claimed unless it is separately verified and tested.

## Voluntary invitation disclosure

The confirmed personal Tibber invitation link is
<https://invite.tibber.com/3mhcd54v>. It is clearly separated from technical
instructions and is not required for installation or use. The benefits are
determined by Tibber's current invitation-program terms and are therefore not
hard-coded in this documentation.

Project information: [153er-netz.de – Development](https://153er-netz.de/seiten/entwicklung.html)
