from datetime import datetime
import OpenSSL 
import ssl 

def GetExpiration(url):
    cert =ssl.get_server_certificate((url, 443)) 
    x509 = OpenSSL.crypto.load_certificate(OpenSSL.crypto.FILETYPE_PEM, cert) 
    bytes=x509.get_notAfter() 
    timestamp = bytes.decode('utf-8') 
    return print(datetime.strptime(timestamp, '%Y%m%d%H%M%S%z').date().isoformat()) 

GetExpiration("www.google.com")

