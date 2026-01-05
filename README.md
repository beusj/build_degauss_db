# Build geocdode.db for DeGAUSS

1. Build the docker image without TIGER/Line data:
   1. `docker build -f Dockerfile -t geocoder-db-builder .`
2. Run the container, mounting a local directory for TIGER/Line data:
   1. `docker run --rm -v ./tiger_data:/tiger_data geocoder-db-builder`
3. Save the resulting database from the container to your local machine:
   1. `docker cp <container_id>:/opt/geocoder.db ./geocoder.db`