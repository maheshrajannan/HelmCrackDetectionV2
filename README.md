# For Normal Domain
 
mkcert concretecrackgallery.in

kubectl create secret tls concrete-gallery-tls --cert=concretecrackgallery.in.pem --key=concretecrackgallery.in-key.pem -n default

Run DOK-deploy pipeline 

mkcert -install


# For Mahesh specific Domain

Run Mahesh-MKCert-TLS-Secret pipeline 

OR follow manual steps below:

mkcert mahesh.concretecrackgallery.in

kubectl create secret tls concrete-gallery-tls --cert=mahesh.concretecrackgallery.in.pem --key=mahesh.concretecrackgallery.in-key.pem -n default

Run Mahesh-DOK-deploy pipeline 

mkcert -install


