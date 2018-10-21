# Lab 4 - Trigger inference as new pictures arrive in s3

In this lab, you will configure your s3 bucket to automatically trigger an inference on your endpoint using images as they arrive in the bucket. Remembering back to the [workshop overview](../README.md), your AWS DeepLens model will be pushing cropped bird images to S3 as it detects them.  The event handling you create in this lab will ensure each bird gets identified using the custom image classification model you created in the first few labs.

Here are the steps involved:

1. Create a Lambda function to identify bird species
2. Test by adding an image to S3

## Step 1 - Create a Lambda function to identify bird species

### Create or select an IAM role for your Lambda function

This Lambda function requires an IAM role with access to SNS, S3, and SageMaker.  Your instructor has created the role on your behalf during workshop preparations.  Go to the IAM console and click on the `Roles` section.  Look for a role called `deeplens-workshop-lambda-role`.  Click on that role and ensure it has access to SNS, S3, and SageMaker, as well as basic Lambda execution permissions (i.e., for CloudWatch logging).

### Create a 'hello world' Lambda function

* Use the Lambda console and click on `Create function` to get started.
* Next, choose to create your function via `Blueprints`.
* Search for the blueprint called `hello-world-python3`.  Select that blueprint and click on `Configure` at the bottom of the page.
* Name the new function `IdentifySpeciesAndNotify`.  
* For IAM role, pick `Choose an existing role` and then pick `service-role/deeplens-workshop-lambda-role` which was created on your behalf before the workshop.
* Click `Create function` at the bottom of the page.

You have successfully created a hello world Lambda function with the appropriate permissions.  You will now customize that function to do what we need it to do in the subsequent steps.

### In the Lambda Designer, add S3 as a Trigger

* Select `S3` in the left hand panel list of possible triggers. It is near the bottom.
* You'll see an `S3` box added to the design panel on the right, and it will say `Configuration required`.  
* Scroll down to the `Configure triggers` section of the designer.
* The first configuration step is to identify which S3 bucket will serve as the event source.  Choose your S3 bucket from the dropdown list (e.g., `deeplens-sagemaker-20181126-roymark`).
* Next, ensure `Object Created(All)` is selcted as the `Event Type`.
* Enter a `Prefix` of `birds/` and a `Suffix` of `.jpg`.
* Ensure `Enable trigger` is selected (it is by default).
* Lastly, click `Add` to add the S3 trigger.
* Click `Save` to save the initial version of the Lambda function.  

The function is now available, and will be triggered when new objects arrive in that bucket.  However, the code for the Lambda function is still simply the default code from the AWS-supplied blueprint.  You will supply the real code required later on in this lab.

### Add environment variables

* At the top of the Lambda designer panel, click on the box with the name of the function (i.e., `IdentifySpeciesAndNotify`).
* Scroll down past the function code below until you reach the `Environment variables` section.
* Enter a new environment variable with `SAGEMAKER_ENDPOINT_NAME` as its key, and `nabirds-species-identifier` for its value.  This tells the function which SageMaker endpoint to use when performing an inference to identify a bird species.  The value must match the name of the endpoint you supplied in [Lab 3](lab3-host-model.md).
* Click `Save` to save your function including the new settings.

### Update the Python code for your function

Before updating the Lambda function to have the required code to predict bird species, first take some time to [review the code](../labs/lab4/lambda/lambda_function.py).  Let's walk through a few key code snippets in the sections below.

#### Code for Invoking the SageMaker endpoint

In the following section of the code, we take the cropped image from S3 as an array of bytes and pass it as the payload to the SageMaker endpoint identified in the Lambda function environment variable.  The inference result comes back as an array of probabilities, each one corresponding to the likelihood that the image represents a bird of that species.

```
payload = s3_object_response['Body'].read()
endpoint_name = os.environ['SAGEMAKER_ENDPOINT_NAME']
endpoint_response = runtime.invoke_endpoint(
                            EndpointName=endpoint_name,
                            ContentType='application/x-image',
                            Body=payload)
result = endpoint_response['Body'].read()
```

#### Code for Parsing the results

Once we have the results of the inference, we turn it into a two-dimensional array with the index of the species and the probability that the image is of that species.  We sort the array in descending probability, with the most likely species first.

```
result = json.loads(result)
indexes = np.empty(len(result))
for i in range(0, len(result)):
    indexes[i] = i
full_results = np.vstack((indexes, result))
transposed_full_results = full_results.T
sorted_transposed_results = transposed_full_results[transposed_full_results[:,1].argsort()[::-1]]
```

#### Code for Creating a human readable message with the results

Given the sorted results, it is straightforward to then construct a message that summarizes what the model predicted.  This can be logged or pushed to SNS (and on to SMS).  If the model's prediction confidence is beyond a configurable threshold, the message definitively states the bird species.  Otherwise, it shows the confidence level of the top two species.  The S3 object key is included in the message to support viewing of the cropped image that was used as input.  A useful extension to this lab would be to provide a signed URL as part of the message that would let the user be one click away from seeing the bird that was sent to the model inference.

```
msg = ''
if (sorted_transposed_results[0][1] > CERTAINTY_THRESHOLD):
    msg = 'Bird [' + key + '] is a: ' + object_categories[int(sorted_transposed_results[0][0])] + '(' + \
            '{:2.2f}'.format(sorted_transposed_results[0][1]) + ')'
else:
    msg = 'Bird [' + key + '] may be a: '
    for top_index in range(0, TOP_K):
        if (top_index > 0):
            msg = msg + ', or '
        msg = msg + object_categories[int(sorted_transposed_results[top_index][0])] + '(' + \
                  '{:2.2f}'.format(sorted_transposed_results[top_index][1]) + ')'
```

#### Code for Publishing the message to SNS

Two simple lines of code are all that we need to publish the message to SNS. One of them is just retrieving the SNS topic ARN from a Lambda environment variable.  This will be added in the optional [Lab 6](lab6-test-notification.md).

```
mySNSTopicARN = os.environ['SNS_TOPIC_ARN']
response = sns.publish(TopicArn=mySNSTopicARN, Message=msg)
```

### Adding 'numpy' support for a Lambda function

The code for this lambda function is provided in `labs/lab4/lambda/lambda_function.py` .  When your Lambda function has an external dependency that is not provided in the default Lambda environment (e.g., Python's `numpy` package), you need to provide those external dependencies in a [Lambda deployment package](https://docs.aws.amazon.com/lambda/latest/dg/lambda-python-how-to-create-deployment-package.html).  

You provide the dependent code by creating a deployment package.  The packaging work in our case is to provide the Python numpy package, and the workshop has done the necessary work for you.  

Note that when deployment packages are used, the function cannot be edited using the Lambda console. Instead, you need to use your own editor of choice.  In this workshop, if you want to make any code changes to the Lambda function, you can navigate to the code in your SageMaker Jupyter notebook in the `Files` tab.  Click through the folders to get to `labs/lab4/lambda/lambda_function.py`.  If you make any changes, simply click on `Save` on the `File` menu to save the changes before deploying the code in the next step.

### Updating the Lambda function

From your SageMaker terminal window, deploying the package is very straightforward, as we have provided a simple shell script to execute:

```
cd ~/SageMaker/bird-classification-workshop/labs/lab4
source ./deploy_lambda.sh
```

The script first creates a zip file containing the code as well as the `numpy` Python package.  It then uses the AWS CLI to deploy the package to Lambda.  This is made possible by having the proper IAM role for the SageMaker notebook instance that lets you update the function code using the Lambda service.  You should receive output similar to the following:

```
...
adding: numpy-1.15.0.dist-info/METADATA (deflated 57%)
adding: numpy-1.15.0.dist-info/INSTALLER (stored 0%)
{
    "FunctionName": "IdentifySpeciesAndNotify",
    "FunctionArn": "arn:aws:lambda:us-east-1:033464141587:function:IdentifySpeciesAndNotify",
    "Runtime": "python3.6",
    "Role": "arn:aws:iam::033464141587:role/service-role/deeplens-workshop-lambda-role",
    "Handler": "lambda_function.lambda_handler",
    "CodeSize": 18889247,
    "Description": "A starter AWS Lambda function.",
    "Timeout": 3,
    "MemorySize": 128,
    "LastModified": "2018-10-11T17:01:16.764+0000",
    "CodeSha256": "534Cp/EnJIkf//lJvWlERqqvXxSYFIiI4hxSBtHCwMU=",
    "Version": "$LATEST",
    "VpcConfig": {
        "SubnetIds": [],
        "SecurityGroupIds": [],
        "VpcId": ""
    },
    "Environment": {
        "Variables": {
            "SAGEMAKER_ENDPOINT_NAME": "nabirds-species-identifier"
        }
    },
    "TracingConfig": {
        "Mode": "PassThrough"
    },
    "RevisionId": "1bc16b77-93bc-420b-b9b8-41a203597bf5"
}
```

## Step 2 - Test by adding an image to S3

### Copy a test image to S3
Copy a test image to S3.  The workshop has a set of test images you can use in the `test_images` folder.  You can use the S3 console to upload an image, or use the AWS CLI as in the following command:

```
aws s3 cp ../../test_images/northern-cardinal.jpg s3://<bucket-name>/birds/`
```

You may have to refresh the S3 console to see the new file in your bucket.  Also, to ensure the Lambda function is triggered, you need to ensure you use the `birds/` prefix for the target object in the S3 bucket.

### Review CloudWatch logs for the Lambda function

Go to the Lambda console.  Click the `Monitoring` tab.  You should see the `Invocations` count go up.  Note that the metrics are not updated instantaneously.  It could take a couple of minutes and a refresh before you see the charts updated.

Now click `View logs in CloudWatch`.  Click on the most recently updated Log Stream. You can identify that by looking at the `Last Event Time` column.

Review the logs.  Look for log entries containing `msg` to see the results of the SageMaker inference.  As you interpret the logs, you will see that each invocation of the function is bracketed by a `START` message at the beginning of the invocation, and a `REPORT` message after completion of the invocation.  Here is a sample set of log output:

```
...
17:34:15 START RequestId: be06fb5e-cd7b-11e8-bd9b-9b286c7b5b1c Version: $LATEST
17:34:15 KEY: birds/card.jpg
17:34:15 CONTENT LENGTH: 106394
17:34:15 CONTENT TYPE: image/jpeg
17:34:15 Invoking bird species identification endpoint
17:34:15 msg: Bird [birds/northern-cardinal.jpg] is a: Northern Cardinal (0.94)
17:34:15 'SNS_TOPIC_ARN'
17:34:15 Error publishing message to SNS.
17:34:15 'SNS_TOPIC_ARN': KeyError Traceback (most recent call  last): File "/var/task/lambda_function.py", line 112, in lambda_handler raise e File "/var/task/lambda_function.py", line 105, in lambda_handler mySNSTopicARN = os.environ['SNS_TOPIC_ARN'] File "/var/lang/lib/python3.6/os.py", line 669, in __getitem__ raise KeyError(key) from None KeyError: 'SNS_TOPIC_ARN'
17:34:15 END RequestId: be06fb5e-cd7b-11e8-bd9b-9b286c7b5b1c
17:34:15 REPORT RequestId: be06fb5e-cd7b-11e8-bd9b-9b286c7b5b1c Duration: 567.73 ms Billed Duration: 600 ms Memory Size: 128 MB Max Memory Used: 67 MB
...
```

Try copying another test image and then go back to the Lambda logs and refresh.

```
aws s3 cp ../../test_images/eastern-bluebird.jpg s3://<bucket-name>/birds/`
aws s3 cp ../../test_images/purple-martin.jpg s3://<bucket-name>/birds/`
```

If you are not finding `msg` entries, you should look for error messages that will help you troubleshoot the problem.

You have now enabled an S3 trigger that will drive invocations of your bird species identifier automatically.  In the next lab, you will integrate an existing off the shelf AWS DeepLens object detection model, extending it to copy cropped images to your S3 bucket whenever it detects a bird via its camera.

## Navigation

Go to the [Next Lab](lab5-deeplens-detect-and-classify.md)

[Home](../README.md) - [Lab 1](lab1-image-prep.md) - [Lab 2](lab2-train-model.md) - [Lab 3](lab3-host-model.md) - [Lab 4](lab4-trigger-inference-from-s3.md) - [Lab 5](lab5-deeplens-detect-and-classify.md) - [Lab 6](lab6-text-notification.md) - [Troubleshooting](troubleshooting.md)
