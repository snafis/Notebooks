0:00
So far in our TensorFlow model we have not been very robust. Think, for example, about our training process. We specified the number of steps that we needed to train. But we know in machine learning that oftentimes, as you train, your training error, the loss on the training dataset, will keep going down. But the model will not generalize the more you train it, right? So at some point, the validation error starts to increase up again. So what we'd really like to be able to do is to train, but only until the point that the error on a validation dataset stops decreasing. In other words, we'd want to do some kind of early stopping. At the same time, we also want to make sure that as when are training, we are continually saving checkpoints as we are going ahead and doing the training. So that if we kill off the training and we restart it, we restart it at the checkpoint location. And we may not want to use the latest checkpoint as our model, but that's what we've been doing so far. So essentially, what we did was that we had a specific number of steps, specific number of epochs, we trained it, and we used the final checkpoint as a model. But in the real world, what we want to do is to train in a distributed way. We want to have our training happen not on one machine but on multiple machines. And if we are doing our training with different numbers of nodes, etc., we might want to chose the model that gives us the best generalization performance. In other words, the one that gives us the least error not in the training set but on a validation dataset. Even as the model is training, we might want to monitor the training, especially if the training is going to take days on end. We want to be able to go and look at what epoch is currently being processed. What is the current error? Should I stop the training, is it not improving? And if you stop the training, and you come back and you have more data, you might want to start back the training often already trained model, you don't want to start from scratch again. You want to be able to resume training. So we want to be able to start training back. We want to be able to do distributed training. We want to be able to choose a model based on a different validation dataset. We want to be able to monitor the training. So even though our TensorFlow model so far got us from point a to point b, essentially we've been just going through in a very haphazard way. What we want is a bridge that gets us from a to b, gets us from raw data to a machine learning model in a much more robust manner. And the way we do this is to use the Experiment class. So in the estimator API, you basically have a class called Experiment, and you create the Experiment passing in a particular estimator. In this case, I'm using a LinearRegressor as my estimator. We create a linear regressor the way we normally do. We create the model exactly the same way, passing in the feature columns, passing in an output_dir. But this output_dir doesn't have to be a local directory. It could even be a folder on cloud storage.
3:36
Then we pass in our training input function. We pass in an evaluation input function. So a training input function gives us features and labels. The dictionary of features and the corresponding labels it loads up the training data. Similarly, you provide an evaluation input function, which loads up another piece of data, the validation dataset, which works very similarly. It also has a dictionary of features. It also has a label. But the difference is that the training dataset is the one that we are actually using for gradient descent. The validation dataset is the thing that we want to use to stop the training, to do early stopping, to do hyperparameter tuning, etc. And the other thing that we can ask for is to tell experiment what metrics to evaluate. So we could say, go ahead and evaluate in addition to the last metric that you're evaluating on the training dataset. On my validation dataset, please evaluate for me the root mean square error. And the way we compute root mean square error is that we use a metric function. And there is already a built-in function that computes a root mean square error. This is useful because you may want to train on a particular last metric. But when you're reporting the error, that may not be the last metric that you want to report for example in classification. We might train on cross entropy, but we might evaluate accuracy and precision and recall.
5:18
Once you have your experiment, you essentially have a callback function that creates an experiment that returns it, and you run that callback function in something called a learn_runner.
5:34
Once you have an experiment up and going, the other thing that you might want to do is that you might want to look at logs. By default, the logging level in TensorFlow is WARN. And so you don't get as much information back. So you can change the verbosity level to INFO.
5:51
In which case you will get more information about the step that something, that TensorFlow is in, the loss of the particular step, etc.. But don't look at the loss here. The loss here is essentially a loss at that particular step. Remember that you do gradient descent on a batch at a time. So this loss is going to be quite noisy. What you really care about often is the evaluation metric. The one that's done over the entire batch.
6:19
So in order to monitor training, in order to look at, for example, the evaluation metric, or the step that it's in, etc., use something called TensorBoard. And you will use TensorBoard in the lab that immediately follows this. 