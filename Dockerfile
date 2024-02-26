FROM python:3-slim as python

ENV DEBIAN_FRONTEND noninteractive

### RUN set -ex; \

RUN apt-get update -qq; \
    apt-get install -y -qq git \
    apt-utils \
    wget \
    build-essential \
    ncbi-blast+ \
    libz-dev \
    ; \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/*;

ENV DEBIAN_FRONTEND Teletype

#Install python dependencies
RUN pip install -U biopython==1.83 tabulate cgecore

# Install kma
RUN git clone --depth 1 https://bitbucket.org/genomicepidemiology/kma.git; \
  cd kma && make; \
  mv kma* /bin/

ADD https://raw.githubusercontent.com/cadms/plasmidfinder/master/plasmidfinder.py /usr/src/plasmidfinder.py

RUN chmod 755 /usr/src/plasmidfinder.py;

ENV PATH $PATH:/usr/src

RUN mkdir /plasmidfinderdb

RUN git clone https://bitbucket.org/genomicepidemiology/plasmidfinder_db.git /plasmidfinderdb
WORKDIR /plasmidfinderdb
RUN PLASMID_DB=$(pwd)
RUN python3 INSTALL.py kma_index

WORKDIR /workdir


