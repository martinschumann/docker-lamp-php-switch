########################
# pki
FROM ubuntu:24.04 AS pki
########################

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

ARG PKI_DIR \
    ROOT_CA_CONF_FILE \
    ROOT_CA_KEY_FILE \
    ROOT_CA_CERT_FILE \
    CONF_FILE \
    CSR_FILE \
    KEY_FILE \
    CERT_FILE

ARG PKI_BIN_DIR=$PKI_DIR/bin
ARG CONF_FILE_PATH=${PKI_DIR}/conf/${CONF_FILE}
ARG ROOT_CA_CONF_FILE_PATH="${PKI_DIR}/root-ca/conf/${ROOT_CA_CONF_FILE}"
ARG ROOT_CA_KEY_FILE_PATH="${PKI_DIR}/root-ca/private/${ROOT_CA_KEY_FILE}"
ARG ROOT_CA_CERT_FILE_PATH="${PKI_DIR}/root-ca/certs/${ROOT_CA_CERT_FILE}"

# Validate
RUN : "${PKI_DIR:?}" \
      "${ROOT_CA_CONF_FILE:?}" \
      "${ROOT_CA_KEY_FILE:?}" \
      "${ROOT_CA_CERT_FILE:?}" \
      "${CONF_FILE:?}" \
      "${CSR_FILE:?}" \
      "${KEY_FILE:?}" \
      "${CERT_FILE:?}"

# Install OpenSSL
RUN apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        openssl \
        ssl-cert && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create folder structure
RUN mkdir -p $PKI_DIR/{bin,conf,certs,crl,csr,private,root-ca/{certs,private,conf}} && \
    chmod 700 $PKI_DIR/{private,root-ca/private}

# Copy utils lib
COPY ./scripts/utils.sh $PKI_BIN_DIR/utils.sh

# Copy and run script for root ca certificate
ENV PKI_DIR=$PKI_DIR \
    ROOT_CA_CONF_FILE_PATH=${ROOT_CA_CONF_FILE_PATH} \
    ROOT_CA_KEY_FILE_PATH=${ROOT_CA_KEY_FILE_PATH} \
    ROOT_CA_CERT_FILE_PATH=${ROOT_CA_CERT_FILE_PATH} \
    CSR_FILE_PATH="${PKI_DIR}/csr/${CSR_FILE}" \
    KEY_FILE_PATH="${PKI_DIR}/private/${KEY_FILE}" \
    CERT_FILE_PATH="${PKI_DIR}/certs/${CERT_FILE}"

COPY ./pki/ssl/conf/ca/$ROOT_CA_CONF_FILE $ROOT_CA_CONF_FILE_PATH
COPY --chmod=755 ./scripts/generate-root-ca-certificate.sh $PKI_BIN_DIR

COPY ./pki/ssl/conf/server/$CONF_FILE $CONF_FILE_PATH
COPY --chmod=755 ./scripts/generate-certificate.sh $PKI_BIN_DIR

RUN $PKI_BIN_DIR/generate-root-ca-certificate.sh
RUN $PKI_BIN_DIR/generate-certificate.sh
