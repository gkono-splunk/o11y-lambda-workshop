# Lambda Tracing Workshop

## Intro
This workshop will equip you to build a distributed trace for a small serverless application that runs on AWS Lambda, producing and consuming a message via AWS Kinesis.

We will see how OpenTelemetry's auto-instrumentation captures traces and exports them to your target of choice.

Next, we will see how we can enable context propagation with manual instrumentation.

For this workshop Splunk has prepared an Ubuntu Linux instance in AWS/EC2 all pre-configured for you. To get access to the instance that you will be using in the workshop, please visit the URL provided by the workshop leader

![Lambda application, not yet instrumented](/guide/images/1-architecture.png)

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

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

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
    - _These commands should output text results for the **access token**, **realm**, and **otel lambda layer** for Splunk Observability Cloud, which your instructor has, or can, share with you._
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

## Auto-Instrumentation

###### Navigate to the `auto` directory
```bash
cd ~/o11y-lambda-workshop/auto
```

Inspect the contents of this directory with the `ls` command. Take a closer look at the `main.tf` file
```bash
more main.tf
```

#### _Workshop Questions_
> _Can you identify which AWS resources are being created by this template?_

> _Can you identify where OpenTelemetry instrumentation is being set up?_
>  - _Hint: study the lambda function definitions starting on line 134_

> _Can you dtermine which instrumentation information is being provided by the environment variables you set earlier?_

You should see a section where the environment variables for each lambda function are being set.
```bash
  environment {
    variables = {
      SPLUNK_ACCESS_TOKEN = var.o11y_access_token
      SPLUNK_REALM = var.o11y_realm
      OTEL_SERVICE_NAME = "producer-lambda"
      OTEL_RESOURCE_ATTRIBUTES = "deployment.environment=${var.prefix}-lambda-shop"
      AWS_LAMBDA_EXEC_WRAPPER = "/opt/nodejs-otel-handler"
      KINESIS_STREAM = aws_kinesis_stream.lambda_streamer.name
    }
  }
```

By using these environment variables, we are configuring and enriching our auto-instrumentation.
- Here, we provide minimum informaiton, such as NodeJS wrapper location in the Splunk APM Layer, environment name, service name, and our Splunk Org credentials.
- We are sending trace data directly to Splunk Observability Cloud.
- You could alternatively export traces to an OpenTelemetry Collector set up in Gateway mode.
- Furthermore, under the Lambda producer resource, you should notice an environment variable for the Kinesis Stream this function will be sending your message to.

You should also see the Splunk OpenTelemetry Lambda layer being added to each function
```bash
  layers = var.otel_lambda_layer
```

You can see the relevant layer ARNs (Amazon Resource Name) and latest versions for each AWS region [HERE](https://github.com/signalfx/lambda-layer-versions/blob/main/splunk-apm/splunk-apm.md) 

Next, let's take a look at the function code.
```bash
more handler/producer.mjs
```
- This NodeJS module contains the code for the producer function.
- Essentially, this function receives a message, and puts a record to the targeted Kinesis Stream

###### Initialize the `auto` directory for Terraform
```bash
terraform init
```
- This enables Terraform to manage the creation, state and destruction of resources, as defined within the `main.tf` file

###### Deploy the Lambda functions and other AWS resources
```bash
terraform apply
```
- respond `yes` when you see the `Enter a value:` prompt
- This will result in the following outputs:
```bash
Outputs:

base_url = "https://______.amazonaws.com/serverless_stage/producer"
consumer_function_name = "_____-consumer"
environment = "______-lambda-shop"
lambda_bucket_name = "lambda-shop-______-______"
producer_function_name = "______-producer"
```

###### Send some traffic to your endpoint
- Ensure you are in the `auto` directory
  - `pwd`
    - The expected output would be **~/o11y-lambda-workshop/auto**
- If you are not in the `auto` directory, run the following command
```bash
cd ~/o11y-lambda-workshop/auto
```

The `send_message.py` script is a Python script that will take input at the command line, add it to a JSON dictionary, and send it to the endpoint for your Lambda producer function repeatedly, as part of a while loop.

- Run the `send_message.py` script
  - It will ask you to input a `name` and a `superpower`
```bash
./send_message.py
Enter you Name (e.g. Damian, Buttercup, etc.)
> 
Enter your Superpower (e.g. flight, super-strength, observability)
>
499 calls left
{"message": "Message placed in the Event Stream: hostname-eventStream"}0
```

- You should see the following output if your message is successful
```bash
{"message": "Message placed in the Event Stream: hostname-eventStream"}0
```
- If unsuccessful, you will see:
```bash
{"message": "Internal server error"}0
```
- If this occurs, ask one of the workshop facilitators for assistance.

------------------------------------------
*** ***VIEW LAMBDA LOGS*** ***
- _PROVIDE THE INSTRUCTIONS FOR THIS STEP_
------------------------------------------

#### View your Lambda Functions in Splunk APM
Now it's time to check how your Lambda traffic has been captured in Splunk APM.

###### View your Splunk APM Overview
- Select `APM` from the Main Menu. This will take you to the Splunk APM Overview.
- Select your APM Environment from the `Environment:` dropdown.
  - _Your APM environment should be in the `PREFIX-lambda-shop` format, where the `PREFIX is obtained from the environment variable you set in the Prerequisites section_

#### _NOTE_
> _It may take a few minutes for your traces to appear in Splunk APM. Try hitting refresh on your browser until you find your environment name in the list of environments._

<!-- Add an image of the environment name in Splunk APM here -->

###### View your Environment's Service Map
- Select `Service Map` on the right side of the APM Overview page.

<!-- Add an image of the Service Map button in Splunk APM here -->

- You should be able to see the `producer-lambda` function and the call it is making to the Kinesis service to put your message as a record

<!-- Add an image of the Service Map page in Splunk APM here with the producer-lambda -> Kinesis functions showing -->

#### _Workshop Question_
> _What about your `consumer-lambda` function?_

###### Explore Lambda Traces
- Click into `Traces` and examins some of the traces generated by the `producer-lambda` function and sent to Splunk Observability Cloud

<!-- Add an image of the Traces button in the Service Map view here -->

- Select a trace to view by clicking on its `Trace ID`

<!-- Add an image of the Traces view here -->

<!-- Add an image of the Trace view for the select Trace -->

We can see that the `producer-lambda` function is putting a record into the Kinesis Stream. But the action of the `consumer-lambda` function is missing!

This is because the trace context is not being propagated. Trace context propagation is not supported out-of-the-box by Kinesis service at the time of this workshop. Our distributed trace stops at the Kinesis service, and we can't see the propagation any further.

Not yet, at least...

Let's see how we work around this in the next section of this workshop

#### Clean Up
- If the `send_message.py` script is still running, stop it with the follwing command
```bash
CTRL+C
```
- Ensure you are in the `auto` directory
  - `pwd`
    - The expected output would be **~/o11y-lambda-workshop/auto**
- If you are not in the `auto` directory, run the following command
```bash
cd ~/o11y-lambda-workshop/auto
```
- Destroy the Lambda functions and other AWS resources you deployed earlier
```bash
terraform destroy
```
- respond `yes` when you see the `Enter a value:` prompt
- This will result in the resources being destroyed, leaving you with a clean environment


## Manual Instrumentation

###### Navigate to the `manual` directory
```bash
cd ~/o11y-lambda-workshop/manual
```

Inspect the contents of this directory with the `ls` command. Take a closer look at the `main.tf` file
```bash
more main.tf
```

#### _Workshop Question_
> _Do you see any difference from the same file in your auto directory?_

###### Compare `auto` and `manual` files
Compare the `main.tf` files in the `auto` and `manual` directories with a `diff` command:
```bash
diff ~/o11y-lambda-workshop/auto/main.tf ~/o11y-lambda-workshop/manual/main.tf
```

There is no difference! (Well, there shouldn't be. Ask your workshop facilitator to assist you if there is)

Now compare the `producer.mjs` files:
```bash
diff ~/o11y-lambda-workshop/auto/handler/producer.mjs ~/o11y-lambda-workshop/manual/handler/producer.mjs
```

There's quite a few differences here!

You may wish to view the entire file and examine its content
```bash
more handler/producer.mjs
```

Notice how we are now importing some OpenTelemetry objects directly into our function to handle some of the manual instrumentation tasks we require.
```js
import { context, propagation, trace, } from "@opentelemetry/api";
```

We are importing the following objects from the [@opentelemetry/api](https://www.npmjs.com/package/@opentelemetry/api) to propagate our context in our producer function.
- context
- propagation
- trace

Finally, compare the `consumer.mjs` files:
```bash
diff ~/o11y-lambda-workshop/auto/handler/consumer.mjs ~/o11y-lambda-workshop/manual/handler/consumer.mjs
```

Here also, there are a few differences of note. Let's take a closer look
```bash
more handler/consumer.mjs
```

In this file, we are importing the following OpenTelemetry objects
- propagation
- trace
- ROOT_CONTEXT

We use these to extract the trace context that was propagated from the producer function

Then to add new span attributes based on our `name` and superpower` to the extracted trace context

#### Inject Trace Context in the Producer Function
The below code executes the following steps inside the producer function:
1. Get the tracer for this trace
2. Initialize a context carrier object
3. Inject the context of the active span into the carrier object
4. Modify the record we are about to pu on our Kinesis stream to include the carrier that will carry the active span's context to the consumer

```js
...
import { context, propagation, trace, } from "@opentelemetry/api";
...
const tracer = trace.getTracer('lambda-app');
...
	return tracer.startActiveSpan('put-record', async(span) => {
		let carrier = {};
		propagation.inject(context.active(), carrier);
		const eventBody = Buffer.from(event.body, 'base64').toString();
		const data = "{\"tracecontext\": " + JSON.stringify(carrier) + ", \"record\": " + eventBody + "}";
		console.log(
			`Record with Trace Context added:
			${data}`
		);

		try {
			await kinesis.send(
				new PutRecordCommand({
				StreamName: streamName,
				PartitionKey: "1234",
				Data: data,
			}),
	
			message = `Message placed in the Event Stream: ${streamName}`
			)
...
		span.end();
```

#### Extract Trace Context in the Consumer Function
The below code executes the following steps inside the consumer function:
1. Extract the context that we obtained from the Producer into a carrier object.
2. Extract the context from the carrier object in Customer function’s parent span context.
3. Start a new span with the parent span context.
4. Bonus: Add extra attributes to your span, including custom ones with the values from your message!
5. Once completed, end the span.
```js
import { propagation, trace, ROOT_CONTEXT } from "@opentelemetry/api";
...
			const carrier = JSON.parse( message ).tracecontext;
			const parentContext = propagation.extract(ROOT_CONTEXT, carrier);
			const tracer = trace.getTracer(process.env.OTEL_SERVICE_NAME);
			const span = tracer.startSpan("Kinesis.getRecord", undefined, parentContext);

			span.setAttribute("span.kind", "server");
			const body = JSON.parse( message ).record;
			if (body.name) {
				span.setAttribute("custom.tag.name", body.name);
			}
			if (body.superpower) {
				span.setAttribute("custom.tag.superpower", body.superpower);
			}
...
			span.end();
```

Now let's see the different this makes!

###### Initialize the `manual` directory for Terraform
- Ensure you are in the `manual` directory
  - `pwd`
    - The expected output would be **~/o11y-lambda-workshop/manual**
- If you are not in the `manual` directory, run the following command
```bash
cd ~/o11y-lambda-workshop/manual
```
```bash
terraform init
```
- This enables Terraform to manage the creation, state and destruction of resources, as defined within the `main.tf` file of the `manual` directory

###### Deploy the Lambda functions and other AWS resources
```bash
terraform apply
```
- respond `yes` when you see the `Enter a value:` prompt
- This will result in the following outputs:
```bash
Outputs:

base_url = "https://______.amazonaws.com/serverless_stage/producer"
consumer_function_name = "_____-consumer"
environment = "______-lambda-shop"
lambda_bucket_name = "lambda-shop-______-______"
producer_function_name = "______-producer"
```
- As you can tell, aside from the first portion of the base_url, the output should be largely the same as when you ran the auto-instrumentation portion of this workshop

###### Send some traffic to your endpoint
- Ensure you are in the `manual` directory
  - `pwd`
    - The expected output would be **~/o11y-lambda-workshop/manual**
- If you are not in the `manual` directory, run the following command
```bash
cd ~/o11y-lambda-workshop/manual
```

- Run the `send_message.py` script
```bash
./send_message.py
Enter you Name (e.g. Damian, Buttercup, etc.)
> 
Enter your Superpower (e.g. flight, super-strength, observability)
>
499 calls left
{"message": "Message placed in the Event Stream: hostname-eventStream"}0
```

- You should see the following output if your message is successful
```bash
{"message": "Message placed in the Event Stream: hostname-eventStream"}0
```
- If unsuccessful, you will see:
```bash
{"message": "Internal server error"}0
```
- If this occurs, ask one of the workshop facilitators for assistance.

------------------------------------------
*** ***VIEW LAMBDA LOGS*** ***
- _PROVIDE THE INSTRUCTIONS FOR THIS STEP_
------------------------------------------

#### View your Lambda Functions in Splunk APM
Let's take a look at the Service Map for our environment in APM once again.

###### View your Splunk APM Overview
- Select `APM` from the Main Menu. This will take you to the Splunk APM Overview.
- Select your APM Environment from the `Environment:` dropdown.
  - _Your APM environment should be in the `PREFIX-lambda-shop` format, where the `PREFIX is obtained from the environment variable you set in the Prerequisites section_

#### _NOTE_
> _It may take a few minutes for your traces to appear in Splunk APM. Try hitting refresh on your browser until you find your environment name in the list of environments._

<!-- Add an image of the environment name in Splunk APM here -->

###### View your Environment's Service Map
- Select `Service Map` on the right side of the APM Overview page.

<!-- Add an image of the Service Map button in Splunk APM here -->

#### _Workshop Question_
> _Notice the difference?_

- You should be able to see the `producer-lambda` function and the call it is making to the `consumer-lambda` function this time

###### Explore Lambda Traces
Next, we will take a look at another trace related to our Environment.

- Click into `Traces` and examins some of the traces generated by the `producer-lambda` function and sent to Splunk Observability Cloud

<!-- Add an image of the Traces button in the Service Map view here -->

- Select a trace to view by clicking on its `Trace ID`

<!-- Add an image of the Traces view here -->

<!-- Paste the value you got from the consumer function's logs into the `View Trace ID` search box under Traces and click `Go` -->

<!-- Add an image of the Traces button and search box in the Service Map view here -->

<!-- Add an image of the Trace view for the select Trace -->

#### _NOTE_
> _Notice that the Trace ID was a part of the trace context that we propagated. The OTel Lambda Layer_

You can read up on two of the most common propagation standards:
1. [W3C](https:///www.w3.org/TR/trace-context/#traceparent-header)
2. [B3](https://github.com/openzipkin/b3-propagation#overall-process)

#### _Workshop Question_
> _Which one are we using?_
  - _The Splunk Distribution of Opentelemetry JS, which supports our NodeJS functions, [defaults](https://docs.splunk.com/observability/en/gdi/get-data-in/application/nodejs/splunk-nodejs-otel-distribution.html#defaults-of-the-splunk-distribution-of-opentelemetry-js) to the `W3C` standard_

#### _Workshop Question_
> _Bonus Question: What happens if we mix and match the W3C and B3 headers?_

Click on the `consumer-lambda` span.

#### _Workshop Question_
> _Can you find the attributes from your message?_

<!-- Add an image of the span attributes for the consumer-lambda span, showing the custom.tag.name and custom.tag.superpower attributes -->

#### Clean Up
- If the `send_message.py` script is still running, stop it with the follwing command
```bash
CTRL+C
```
- Ensure you are in the `manual` directory
  - `pwd`
    - The expected output would be **~/o11y-lambda-workshop/manual**
- If you are not in the `manual` directory, run the following command
```bash
cd ~/o11y-lambda-workshop/manual
```
- Destroy the Lambda functions and other AWS resources you deployed earlier
```bash
terraform destroy
```
- respond `yes` when you see the `Enter a value:` prompt
- This will result in the resources being destroyed, leaving you with a clean environment

## Conclusion

Congratulations on finishing the workshop. You have seen how we can complement auto-instrumentation with manual steps to force the `producer-lambda` function's context to be sent to the `consumer-lambda` function via a record in a Kinesis stream. This allowed us to build the expected Distributed Trace, and to contextualize the relationship between both functions in Splunk APM.

![Lambda application, now fully instrumented](/guide/images/7-conclusion-1-architecture.png)

You can now build out a trace manually by linking two different functions together. This is very power when your auto-instrumentation, or 3rd-party systems, do not support context propagation out of the box.