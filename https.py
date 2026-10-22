"""
Run an HTTPS server serving the contents of the directory.

You'll need to generate a key and certificate file. On a Mac you should do this by following
the instructions in:

https://developer.apple.com/library/archive/technotes/tn2326/_index.html

First "Creating a Certificate Authority" and then "Issuing a [server] Digital Identity"

This will generate a self-signed root Certificate Authority (CA) certificate and a signed server
certificate (digital identity) to be used by your server.

You then need to export the certificate authority certificate
as a .cer file through KeyChain by

- right click the CA certificate
- hit Export...
- select the .cer format

Then add it to you test iOS device by

- emailing it to yourself
- tapping on the .cer attachment
- installing it and trusting it
- enabling it through Settings -> General -> About -> Certificate Trust Settings

Then you need to export the signed server cert, this time using format
"Personal Information Exchange" (.p12) so that it includes the private key, then convert it to
pem using openssl like this:

    openssl pkcs12 -in your-export.p12 -nocerts -nodes -out your-server.key
    openssl pkcs12 -in your-export.p12 -nokeys -nodes -out your-server.cer

You can then run this server like this:

    python3 https.py --port 4443 your-server.key your-server.cer

By default this listens to all addresses by using the ipv6 null address :: – this *also* listens
for ipv4 connections (!).

☝🏽 If you get an error like `routines:inner_evp_generic_fetch:unsupported:crypto`, then you can
try adding the -legacy option, or you probably have to change one of the certificate's default
parameters.
"""
import argparse
import http.server
import socket
import ssl


class HTTPServerV6(http.server.HTTPServer):
    address_family = socket.AF_INET6


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run an HTTPS server to serve your current directory')
    parser.add_argument('keyfile')
    parser.add_argument('certfile')
    parser.add_argument('--host', default='')
    parser.add_argument('--port', type=int, default=4443)
    args = parser.parse_args()

    print(f'Using keyfile {args.keyfile}')
    print(f'Using certificate {args.certfile}')
    httpd = HTTPServerV6(
        (args.host, args.port), http.server.SimpleHTTPRequestHandler
    )
    print(f'Listening on address {httpd.server_address}')
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(args.certfile, keyfile=args.keyfile)
    httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
    httpd.serve_forever()
