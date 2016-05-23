# # The following two commands remove any previously installed H2O packages for R.
# if ("package:h2o" %in% search()) { detach("package:h2o", unload=TRUE) }
# if ("h2o" %in% rownames(installed.packages())) { remove.packages("h2o") }
# 
# # Next, we download packages that H2O depends on.
# pkgs <- c("methods","statmod","stats","graphics","RCurl","jsonlite","tools","utils")
# for (pkg in pkgs) {
#   if (! (pkg %in% rownames(installed.packages()))) { install.packages(pkg) }
# }
# 
# # Now we download, install and initialize the H2O package for R.
# install.packages("h2o", type="source", repos=(c("http://h2o-release.s3.amazonaws.com/h2o/rel-turchin/3/R")))
library(h2o)
library(data.table)
localH2O = h2o.init(nthreads=-1)

cat("reading the train and test data (with data.table) \n")
train <- fread("/Users/nabil/Downloads/numerai_datasets/numerai_training_data.csv")
test <- fread("/Users/nabil/Downloads/numerai_datasets/numerai_tournament_data.csv")

# trasnform Target to Enum (this is Classification problem)

train[,target:=as.factor(as.numeric(target))]

cat("train data column names and details\n")
summary(train)

## Load data into cluster from R
trainHex<-as.h2o(train)

## get All features (Expect only Target)
features<-colnames(train)[!(colnames(train) %in% c("target"))]

## Train a random forest using all default parameters
rfHex <- h2o.randomForest(model_id = 'RF_FIRST_MODEL',
                          nfolds = 5,
                          x=features,
                          y="target",
                          ntrees = 1000,
                          max_depth = 30,
                          training_frame=trainHex)

summary(rfHex)

cat("Predicting Target\n")
testHex<-as.h2o(test)

## Get predictions out; predicts in H2O, as.data.frame gets them into R
predictions<-as.data.frame(h2o.predict(rfHex,testHex))

## Return the predictions to the original scale of the Sales data
pred <- predictions[,1]
summary(pred)
submission <- data.frame(t_id=test$t_id, probability=pred)

cat("saving the submission file\n")
write.csv(submission, "h2o_numerai_rf.csv",row.names=F)
