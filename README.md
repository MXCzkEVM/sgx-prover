# sgx-prover

This is a docker config to run a SGX prover for Moonchain.



## Setup of host system

Target: Ubuntu Server 22.04 (LTS)



1> Update system.

```
sudo apt update && sudo apt upgrade -y
```



2> If the Linux Kernel is not 6.x, please update it. After updated, please reboot.

```
sudo apt install -y linux-image-6.8.0-49-generic
```



3> Install packages

```
sudo apt install -y vim openssl net-tools inetutils-ping cmake apt-utils git ssh build-essential unzip curl wget pkg-config libssl-dev libcap-dev jq tzdata cpuid gawk clang python-is-python3 debhelper zip libcurl4-openssl-dev libboost-dev libboost-system-dev libboost-thread-dev protobuf-c-compiler libprotobuf-c-dev protobuf-compiler jq

sudo apt install --reinstall ca-certificates && sudo update-ca-certificates --fresh
```



4> Install docker.

```
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker ${USER}
```



5> Install nodejs.

```
curl -s https://deb.nodesource.com/setup_20.x | sudo bash
sudo apt install -y nodejs
```



6> Install Gramine.

```
sudo curl -fsSLo /etc/apt/keyrings/gramine-keyring-$(lsb_release -sc 2>/dev/null).gpg https://packages.gramineproject.io/gramine-keyring-$(lsb_release -sc 2>/dev/null).gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/gramine-keyring-$(lsb_release -sc 2>/dev/null).gpg] https://packages.gramineproject.io/ $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/gramine.list

sudo curl -fsSLo /etc/apt/keyrings/intel-sgx-deb.asc https://download.01.org/intel-sgx/sgx_repo/ubuntu/intel-sgx-deb.key
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/intel-sgx-deb.asc] https://download.01.org/intel-sgx/sgx_repo/ubuntu $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/intel-sgx.list

sudo apt update
sudo apt install -y gramine sgx-pck-id-retrieval-tool
```



7> Check FMSPC, it should be `00706A800000` for the supported hardware.

```
echo "Please enter Intel's PCS Service API key" && read -r API_KEY && sudo PCKIDRetrievalTool -f /tmp/pckid.csv && pckid=$(cat /tmp/pckid.csv) && ppid=$(echo "$pckid" | awk -F "," '{print $1}') && cpusvn=$(echo "$pckid" | awk -F "," '{print $3}') && pcesvn=$(echo "$pckid" | awk -F "," '{print $4}') && pceid=$(echo "$pckid" | awk -F "," '{print $2}') && curl -v "https://api.trustedservices.intel.com/sgx/certification/v4/pckcert?encrypted_ppid=${ppid}&cpusvn=${cpusvn}&pcesvn=${pcesvn}&pceid=${pceid}" -H "Ocp-Apim-Subscription-Key:${API_KEY}" 2>&1 | grep -i "SGX-FMSPC"
```

You may reference to this [Intel's how-to guide](https://www.intel.com/content/www/us/en/developer/articles/guide/intel-software-guard-extensions-data-center-attestation-primitives-quick-install-guide.html) to get the API key.



## Installation

1> Create a target installation folder. For example `/opt/sgx-prover`.

```
mkdir /opt/moonchain
```



2> Checkout the repos and ready the folder.

```
cd /opt/moonchain
git clone https://github.com/MXCzkEVM/sgx-prover.git
mkdir -p log/raiko
mkdir -p config/sgx-pccs
mkdir -p config/raiko/config
mkdir -p config/raiko/secrets
```



3> Setup PCCS. You may answer the cert info with, Country Name=DE, State=Berlin, Organization Name=moonchain, Common Name=moonchain and leave it blank for others which not mentioned. Or answer with your own information.

```
cd /opt/moonchain
cp sgx-prover/archives/sgx-pccs/default.json config/sgx-pccs/
cd config/sgx-pccs
openssl genrsa -out private.pem 2048
chmod 644 private.pem
openssl req -new -key private.pem -out csr.pem
openssl x509 -req -days 3650 -in csr.pem -signkey private.pem -out file.crt
rm csr.pem
```



4> Set the API key for Intel PCS service inside the `default.json` file.

```
    "ApiKey": "",   <-- Put the primary API key and a secondary API key here
```

Ref: [Intel's how-to guide](https://www.intel.com/content/www/us/en/developer/articles/guide/intel-software-guard-extensions-data-center-attestation-primitives-quick-install-guide.html)



5> Init raiko.

```
cd /opt/moonchain
cp sgx-prover/archives/moonchain.json config/
cd sgx-prover
docker compose up init
docker compose down
```

You can find the quote string at `/opt/moonchain/config/raiko/config/bootstrap.json`.



6> Register with the SGX quote and got the instance id. Ref: [RegistorToMoonchain.md](doc/RegistorToMoonchain.md).



7> Update instance id to `config/moonchain.json`.



8> Start the prover.

For Moonchain Geneva Testnet:

```
cd /opt/moonchain
cd sgx-prover
./start_moonchain_testnet.sh
```

For Moonchain Geneva Mainnet:

```
cd /opt/moonchain
cd sgx-prover
./start_moonchain_mainnet.sh
```





## Metrics

### Metrics for Prometheus request

URL (GET):

```
http://172.33.0.1:8182/metrics
```

Example response:

```
# HELP timePerProof Average time (in second) used to generate a proof.
# TYPE timePerProof gauge
timePerProof 69

# HELP successJobs5m Number of success proof job per 5 minutes.
# TYPE successJobs5m gauge
successJobs5m 3

# HELP failJobs5m Number of failed proof job per 5 minutes.
# TYPE failJobs5m gauge
failJobs5m 0
```



### Get metrics in JSON

URL (GET):

```
http://172.33.0.1:8182/jsonMetrics
```

Example response:

```
{"timePerProof":69,"successJobs5m":3,"failJobs5m":0}
```

