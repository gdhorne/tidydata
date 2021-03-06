library(dplyr)

################################################################################
#
# Source: University of California at Irvine, Machine Learning Repository, Center 
# for Machine Learning and Intelligent Systems.
#
#     http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones
#
# Bibliography:
# 
#       Davide Anguita, Alessandro Ghio, Luca Oneto, Xavier Parra and 
#       Jorge L. Reyes-Ortiz. A Public Domain Dataset for Human Activity 
#       Recognition Using Smartphones. 21th European Symposium on Artificial
#       Neural Networks, Computational Intelligence and Machine Learning, 
#       ESANN 2013. Bruges, Belgium 24-26 April 2013.
################################################################################

################################################################################
# Step 0: Obtain the Human Activity Recognition Using Smartphones Data
################################################################################

# Fetch the activity monitoring data from the Getting and Cleaniung Data 
# fileshare on Amazon Web Services.

if (!file.exists("uci_dataset.zip")) {
    url <- paste("https://d396qusza40orc.cloudfront.net",
                 "/getdata/projectfiles/UCI%20HAR%20Dataset.zip", sep = "")
    download.file(url, "uci_dataset.zip", "curl", TRUE)
}

# Extract the archive contents to the current working subdirectory.

if (!file.exists("UCI HAR Dataset")) {
    unzip("uci_dataset.zip")   
}

################################################################################

################################################################################
# Step 1: Merge the training dataset and the testing dataset
################################################################################

# Read the activity labels and features to be applied to the training and 
# testing datasets.

activity.names <- read.table('UCI HAR Dataset/activity_labels.txt', 
                             as.is = TRUE)[, 2]
variable.names <- read.table('UCI HAR Dataset/features.txt', as.is = TRUE)[, 2]

# Read the activity, subject, and measurement values for each of the training 
# and testing datasets.

test.activities <- read.table("UCI HAR Dataset/test/y_test.txt")
train.activities <- read.table("UCI HAR Dataset/train/y_train.txt")

test.subjects <- read.table("UCI HAR Dataset/test/subject_test.txt")
train.subjects <- read.table("UCI HAR Dataset/train/subject_train.txt")

test.measurements <- read.table('UCI HAR Dataset/test/X_test.txt')
train.measurements <- read.table('UCI HAR Dataset/train/X_train.txt')

# Combine column-wise the subjects, activities, and measurements after row-wise 
# merging the training and testing components in a row-wise.

dataset <- 
    cbind(
        rbind(train.subjects, test.subjects), 
        rbind(train.activities, test.activities),
        rbind(train.measurements, test.measurements)
    )

################################################################################

################################################################################
# Step 2: Extract only the measurements on the mean and standard deviation for 
#         each measurement
################################################################################

# Associate variable names with each column of the combined dataset in 
# preparation to extract only the measurements of interest.

names(dataset) <- c("subject", "activity", variable.names)
dataset <- dataset[, grep("subject|activity|mean|std", names(dataset))]

################################################################################

################################################################################
# Step 3: Make descriptive activity names for each activitiy
################################################################################

# Remove underscores from the existing activity names before converting them to 
# lowercase and making these the descriptive activity names.

activity.names <- 
    tolower(
        paste(
            substr(activity.names, 1, 1), 
            sub("_", "", substr(activity.names, 2, max(nchar(activity.names)))), 
            sep = ""
        )
    )

dataset$activity <- activity.names[dataset$activity]

################################################################################

################################################################################
# Step 4: Label the data set with descriptive variable names
################################################################################

# Normalise the variable names.

# Rules:
#  [1] lowercase variable names
#  [2] domain format: [t|f]
#       f: Fast Fourier Transform
#       t: time
#      subdomain: (t) t[body[accelerometer|gyroscope]|gravityaccelerometer], 
#                 (f) fbodyaccelerometer
#  [3] axis designator format: [x|y|z]axis
#  [4] axis statistic format: [x|y|z]axis[mean|std]

# Handle unique single-characters before converting all variable names to 
# lowercase.

variable.names <- colnames(dataset)
variable.names <- sub("X", "xaxis", variable.names)
variable.names <- sub("Y", "yaxis", variable.names)
variable.names <- sub("Z", "zaxis", variable.names)

# Now it is safe to handle unambiguous substitutions.

variable.names <- tolower(variable.names)
variable.names <- sub("mag", "magnitude", variable.names)
variable.names <- sub("acc", "accelerometer", variable.names)
variable.names <- sub("gyro", "gyroscope", variable.names)
variable.names <- gsub("\\-", "", variable.names)
variable.names <- sub("\\(\\)", "", variable.names)

variable.names <- sub("bodybody", "body", variable.names)
variable.names <- sub("meanxaxis", "xaxismean", variable.names)
variable.names <- sub("meanyaxis", "yaxismean", variable.names)
variable.names <- sub("meanzaxis", "zaxismean", variable.names)
variable.names <- sub("stdxaxis", "xaxisstd", variable.names)
variable.names <- sub("stdyaxis", "yaxisstd", variable.names)
variable.names <- sub("stdzaxis", "zaxisstd", variable.names)

names(dataset) <- variable.names
dataset <- dataset[, grep("subject|activity|mean$|std$", colnames(dataset))]

################################################################################

################################################################################
# Step 5:  Creates a second, independent tidy dataset with the computed average 
#          (mean) of each variable for each activity and each subject
################################################################################

# Create a tidy dataset for subsequent analysis.
# Criteria: Compute the mean for each subject and each activity.

#tidydata <- melt(dataset, id=c("subject", "activity"), 
#                 measure.vars = colnames(dataset[, grep("mean|std", 
#                                                        colnames(dataset))]))
#tidydata <- dcast(tidydata, subject + activity ~ variable, mean)

tidydata <- group_by(dataset, subject, activity) %>% summarise_each(c("mean"))

# Save tidy dataset to file.
write.table(tidydata, file="tidydata.txt", row.names = FALSE)
# tidydata <- read.table("tidydata.txt", header = TRUE)

################################################################################

# Clean-up the environment leaving it as you found it.

rm("activity.names", "variable.names",
   "test.activities", "train.activities",
   "test.measurements","train.measurements",
   "test.subjects", "train.subjects")
rm("dataset", "tidydata")
