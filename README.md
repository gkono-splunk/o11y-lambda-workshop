# Lambda Tracing Workshop

## Prerequisites

#### Observability Workshop Instance
- Your workshop instructor will have provided you with your credentials to access your instance
- Alternatively, you would have deployed a local observability workshop instance using Multipass

#### AWS Command Line Interface (aws-cli)
- check if the **aws** command is installed on your instance
  - `which aws`
    - _The expected output would be **/usr/local/bin/aws**_
- If the **aws** command is not installed on your instance, run the following command
```bash
sudo apt install awscli
```

#### Terraform
- check if the **terraform** command is installed on your instance
  - `which terraform`
    - _The expected output would be **/usr/local/bin/terraform**_
- If the **terraform** command is not installed on your instance, follow Terraform's recommended installation commands listed below:
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```
```bash
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```
```bash
sudo apt update && sudo apt install terraform
```

#### Workshop
- Confirm you have the workshop directory in your home directory
  - `cd && ls`
    - _The expected output would include **o11y-lambda-workshop**_
  - If the **o11y-lambda-workshop** directory is not in your home directory, clone it with the following command:
```bash
git clone https://github.com/gkono-splunk/o11y-lambda-workshop.git
```

#### AWS & Terraform Variables

###### AWS
- Ensure you have the following environment variables set for AWS access:
  - `echo $ACCESS_KEY_ID`
  - `echo $SECRET_ACCESS_KEY`
    - _These commands should output text results for the **access key ID** and **secret access key** your instructor shared with you_
  - If the AWS environment variables aren't set, request those keys from your instructor, and input them in the following manner
```bash
export ACCESS_KEY_ID=provided_access_key_id
export SECRET_ACCESS_KEY=provided_secret_access_key
```

###### Terraform
- Ensure you have the following environment variables set for AWS access:
  - `echo $TF_VAR_o11y_access_token`
  - `echo $TF_VAR_o11y_realm`
  - `echo $TF_VAR_otel_lambda_layer` 
  - `echo $TF_VAR_prefix`
    - _These commands should output text results for the **access token**, **realm**, and **otel lambda layer** for Splunk Observability Cloud, which your instructor has, or can, share with you.
    - _Also there should be an output for the **prefix** that will be used to name your resources. It will be a value that you provide_
  - If the Terraform environment variables aren't set, Do the following:
    - Request the **access token**, **realm**, and **otel lambda layer** from your instructor
    - Replace the **CHANGEME** values for the following variables, then copy and paste them into your command line
```bash
export TF_VAR_o11y_access_token="CHANGEME"
export TF_VAR_o11y_realm="CHANGEME"
export TF_VAR_otel_lambda_layer='["CHANGEME"]'
export TF_VAR_prefix="CHANGEME"
```


* Auto-Instrumentation
    * cd ~/o11y-lambda-workshop/auto
    * terraform init
    * terraform apply
        * yes
        *  outputs
    * ./send_message.py
        * name
        * superpower
    * **View Lambda Logs
* Lambdas in Splunk APM
    * APM
    * Environment
    * Service Map
        * producer-lambda -> Kinesis
    * Traces
    * Lack of context propagation on consumer-lambda
    * terraform destroy
        * yes
* Manual Instrumentation
    * cd ~/o11y-lambda-workshop/manual
    * terraform init
    * terraform apply
        * yes
        * outputs
    * ./send_message.py
        * name
        * superpower
* Updated Lambdas in Splunk APM
    * APM
    * Environment
    * Service Map
        * producer-lambda -> consumer-lambda
    * Traces
        * Trace
            * consumer-lambda span
                * Span tags
                    * custom.tag.name
                    * custom.tag.superpower
    * terraform destroy
        * yes

