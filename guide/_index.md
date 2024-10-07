---
title: Build a Distributed Trace in Lambda and Kinesis
linkTitle: Lambda Tracing and Kinesis
description: This workshop will demonstrate how to construct and observe a distributed trace for a small serverless application that runs on AWS Lambda, producing and consuming a message via AWS Kinesis 
weight: 6
authors: ["Guy-Francis Kono"]
time: 45 minutes
---

This workshop will demonstrate how to construct and observe a distributed trace for a small serverless application that runs on AWS Lambda, producing and consuming a message via AWS Kinesis.

We will see how auto-instrumentation works, as well as manual steps to force a Producer function's context to be sent to Consumer function via a Record put on a Kinesis stream.

For this workshop Splunk has prepared an Ubuntu Linux instance in AWS/EC2 all pre-configured for you.

To get access to the instance that you will be using in the workshop, please visit the URL provided by the workshop leader.