> docker build -t berejant/nomeroff-api:v0.1 .

> docker run -p 8020:8020 -it berejant/nomeroff-api:v0.1

> curl http://localhost:8020/ -X POST  --data-binary @{path_to_image_jpg}

