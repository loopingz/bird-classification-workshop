# Lab 2 - Train the classification model

In this lab, you will train an image classification model to identify bird species.
Here are the steps involved:

1. Understand SageMaker's built in Image Classification algorithm
2. Create a SageMaker training job, including the hyperparameters
4. View the results of the training

## Understand SageMaker's Image Classification algorithm

## Create a SageMaker training job, including the hyperparameters

Follow these steps to create a SageMaker training job which will create your bird species identification model:

* Pick a name for the job.
* Choose 'Image classification' from the built in list of algorithms.
* Choose 'ml.p2.xlarge' instance type.  Note that your account must have its resource limit increased beyond the default of 0.  The p2 and p3 instance families provide GPU's, which are required for SageMaker's image classification algorithm.
* Define 2 data channels.  Content type 'application/x-recordio'. Compression type: None, Record wrapper type: None, Data type: S3Prefix, S3 data distribution type: FullyReplicated. URI: s3://<bucket-name>/train/ . S3 output path: s3://<bucket-name>/output .

Define the hyperparameters:
* augmentation_type 'crop'.
* checkpoint_frequency: 15.
* epochs: 15.  For this size dataset on the selected instance type, 15 epochs will allow the job to complete in around 6 minutes with reasonable accuracy.  If you had more time available, you could improve the accuracy by doubling the number of epochs.
* image_shape: '3,224,224'.
* learning_rate: 0.1.
* lr_scheduler_factor: 0.1.
* mini_batch_size: 24.
* num_classes: 4.
* num_layers: 152.
* num_training_samples: 335.
* optimizer: sgd.
* use_pretrained_model: 0.
* all other parameters: use default values.

Click on "Create training job", which will create the job and launch it on the selected instance type.

## View the results of the training

Click on training job to view details.

Click on 'view logs'.

Pick the latest log stream.

Should see logging of progress for each epoch.  Pay attention to 'Validation-accuracy', as it should be steadily increasing.

Provide script or Jupyter notebook to view the accuracy progress by epoch.

Results are saved in model.tar.gz in the specified output directory.  That will be used to create a model for inference.
