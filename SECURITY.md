# Security policy

## Supported development state

This repository is a public release candidate under active development. It is
not an official FHEM module and has no supported stable release yet.

## Reporting

Report suspected vulnerabilities privately to the repository owner. Do not open a public issue containing an access token, home identifier, address, meter identifier, UUID, configuration export or production log.

## Secret-handling rules

- Never commit personal Tibber access tokens, OAuth secrets or copied FHEM configuration/state.
- Use only synthetic identifiers and data in tests, examples and documentation.
- Mask authorization material and identifiers in diagnostics before they reach FHEM readings or logs.
- Revoke a token immediately if it is accidentally disclosed.
- Release verification must scan tracked files and the generated package for secret-shaped content.

The protected FHEM key-value store is the intended token location for the finished module. Legacy plaintext definitions receive an explicit migration path; the module must not silently rewrite user configuration.
