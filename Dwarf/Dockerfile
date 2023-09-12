# Base image
FROM python:3.9

RUN echo "deb https://archive.debian.org/debian stretch main" > /etc/apt/sources.list

# Install required system packages
RUN apt-get update && apt-get install -y \
    iproute2 \
    inotify-tools \
    net-tools \
    tcpdump \
    libpcap-dev

# Set the working directory
WORKDIR /app

# Copy the application files to the container
COPY dwarf.sh /app/
COPY variables.txt /app/
COPY api.py /app/
COPY request.py /app/
COPY templates/index.html /app/templates/

# Install Python dependencies
RUN pip install flask requests

# Expose the necessary port
EXPOSE 8082

# Run the application
CMD sh -c "./dwarf.sh & python3 api.py"

