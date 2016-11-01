FROM gettyimages/spark

MAINTAINER Thuong Dinh "https://github.com/thuongdinh"

# ANACONDA 3

RUN apt-get update --fix-missing && apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 \
    git mercurial subversion

RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/archive/Anaconda3-4.2.0-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh

RUN apt-get install -y curl grep sed dpkg && \
    TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb && \
    apt-get clean

ENV PATH /opt/conda/bin:$PATH

# Install XGBoost library
RUN apt-get update --fix-missing && apt-get install -y gfortran libatlas-base-dev gfortran pkg-config \
            libfreetype6-dev libxft-dev libpng-dev libhdf5-serial-dev g++ \
            make patch lib32ncurses5-dev

USER root

# install gcc with openmp support in conda
RUN conda install -y gcc

# download and build xgboost
RUN cd /opt && \
  git clone --recursive https://github.com/dmlc/xgboost && \
  cd xgboost && \
  make -j4

# set environment var to python package for both python2 and python3
ENV PYTHONPATH /opt/xgboost/python-package

# install R package - use pre-compiled CRAN version
RUN Rscript -e "install.packages('xgboost',repos='http://cran.rstudio.com/')"

USER $NB_USER

WORKDIR $SPARK_HOME
CMD ["bin/spark-class", "org.apache.spark.deploy.master.Master"]