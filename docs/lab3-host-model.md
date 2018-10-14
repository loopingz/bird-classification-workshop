# Lab 3 - Host the inference model and identify your first bird!

In this lab, you will host the inference model and identify your first bird!  

Here are the steps:

1. Create a SageMaker model from the training artifacts
2. Create a SageMaker endpoint configuration
3. Create a SageMaker endpoint
4. Test your model using the endpoint

## Create a SageMaker model

### Create the model using the console

* Click on `Models` in the `Inference` section of the left hand panel of the SageMaker console.
* Click on `Create model`.
* Give the model a name such as `birds`.
* Leave the model with the default IAM role such as `AmazonSageMaker-ExecutionRole-20180926T121970`.
* Leave the Network setting as `No VPC`.
* Set the Primary container to the location of SageMaker's inference code image for `us-east-1` which is:
 `811284229777.dkr.ecr.us-east-1.amazonaws.com/image-classification:1`.
* Set the location of model artifacts to the full path of the trained model created in Lab 2 (something like: `s3://<bucket-name>/<job-name>/output/model.tar.gz`, remembering to replace `<bucket-name>` with the name of your bucket and `<job-name>` with the name of your training job from [Lab 2](lab2-train-model.md).  To ensure you get the precise URI, you can copy it from the `Output` section of the training job details page.
* Click `Create model`, and it will now show up in your list of models.

## Create a SageMaker endpoint configuration

* Click on `Endpoint configurations` in the `Inference` section of the left hand panel of the SageMaker console.
* Click on `Create endpoint configuration`.
* Give the endpoint configuration a name such as `birds`.
* Click on `Add model` and pick the model you just created in the previous step.
* Click on `Save`.
* Click on `Create endpoint configuration`, and your new endpoint configuration will now show up in the list of endpoint configurations.

## Create a SageMaker endpoint

* Click on `Endpoints` in the `Inference` section of the left hand panel of the SageMaker console.
* Click on `Create endpoint`.
* Give it a specific name that will be referenced from other labs: `nabirds-species-identifier`.
* In the `Endpoint configuration` section, select the endpoint configuration that you just created in the previous step.
* Click on `Create endpoint` at the bottom of the page, and SageMaker will create an endpoint for you.  The creation process will take several minutes.  Note that once the endpoint is in the running state, you will be billed until the endpoint is deleted.

## Test your model from a SageMaker terminal window

Return to your SageMaker Jupyter notebook and click on the `New` button on the upper right hand side of the notebook in the `Files` tab.  Select `Terminal` from the dropdown list.  This will open a new terminal window running on your SageMaker notebook instance.  From that window, you have direct access to the full set of lab materials such as the raw input images you explored in [Lab 1](lab1-image-prep.md), along with the packaged RecordIO files you created in that same lab.

In this section, you will use some images that your model has never seen before and run tests against the inference endpoint you created earlier in this lab.

You will be executing the following [test script](../labs/lab3/test_direct_sample.py).  You will not be able to test against the endpoint until its status moves from `Creating` to `InService`.  Once the endpoint is in service, navigate to the Lab 3 folder from the terminal window, and run the test using Python:

```
cd ~/SageMaker/bird-classification-workshop/labs/lab3
python test_direct_sample.py ../../test_images/northern-cardinal.jpg
```

This will invoke the SageMaker endpoint, parse the results, create and print a message telling you which bird species was identified.  If the confidence level was low, it will tell you the top 2 candidates.  Confidence levels are also printed.

You should see output like the following:

```
Bird is a: Northern Cardinal (0.98)[772]
```

Try the other images provided in the `test_images` folder and see how accurate your model is predicting its species.

## Navigation

Go to the [Next Lab](lab4-trigger-inference-from-s3.md)

[Home](../README.md) - [Lab 1](lab1-image-prep.md) - [Lab 2](lab2-train-model.md) - [Lab 3](lab3-host-model.md) - [Lab 4](lab4-trigger-inference-from-s3.md) - [Lab 5](lab5-deeplens-detect-and-classify.md) - [Lab 6](lab6-text-notification.md) - [Troubleshooting](troubleshooting.md)
