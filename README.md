> docker build -t berejant/nomeroff-api:v0.1 .

> docker run -p 8080:8080 -it nomeroff -d --restart always berejant/nomeroff-api:v3.1.0


Check that contiainer works:
```commandline
curl --fail -s https://raw.githubusercontent.com/ria-com/nomeroff-net/v3.1.0/data/examples/oneline_images/example1.jpeg | \
curl http://localhost:8080/ -X POST --data-binary @- 
```

How to send any other image
> curl http://localhost:8080/ -X POST  --data-binary @{PATH_TO_IMAGE_FILE}
