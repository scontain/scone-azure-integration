#!/bin/bash
if [ -z "$SCONE_CAS_ADDR" ]; then
   echo "ERROR - Please specify \$SCONE_CAS_ADDR."
   exit 1
fi

# Parse CAS address.
# If provided SCONE_CAS_ADDR is an IPv4 address,
# create an entry for "cas" in /etc/hosts with
# such address. This is needed because SCONE CLI
# does not support IP addresses when attesting a CAS.
# If the provided SCONE_CAS_ADDR is a name, just use it.
if [[ -z "$SCONE_CAS_ADDR" ]]; then
    CAS_ADDR="cas"
elif [[ $SCONE_CAS_ADDR =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    # NOTE: checking only for a generic IPv4 format (with no octet validation).
    CAS_ADDR="cas"
    echo "$SCONE_CAS_ADDR $CAS_ADDR" >> /etc/hosts
else
    CAS_ADDR=$SCONE_CAS_ADDR
fi

# Attest CAS.
# Attest CAS before uploading the session file. Please note that this is for testing only.
# Accept any CAS (--only_for_testing-trust-any) signed by anyone (--only_for_testing-ignore-signer).
# Tolerate debug mode (--only_for_testing-debug), outdated TCB (-G), hyper-threading enabled (-C) and
# software hardening needed (-S) .
scone cas attest -G -C -S --only_for_testing-debug --only_for_testing-ignore-signer --only_for_testing-trust-any "$CAS_ADDR"